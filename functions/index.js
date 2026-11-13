const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

initializeApp();
const db = getFirestore();

exports.createOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in to place an order.");
  }

  const input = request.data?.deliveryDetails;
  const requiredFields = [
    ["fullName", 2, 100],
    ["phone", 10, 16],
    ["province", 2, 60],
    ["city", 2, 80],
    ["area", 2, 100],
    ["address", 5, 300],
  ];
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw new HttpsError("invalid-argument", "Enter complete delivery details.");
  }
  const deliveryDetails = {};
  for (const [field, minimum, maximum] of requiredFields) {
    const value = input[field];
    if (typeof value !== "string" || value.trim().length < minimum ||
        value.trim().length > maximum) {
      throw new HttpsError(
        "invalid-argument",
        `Enter a valid ${field.replace(/[A-Z]/g, (letter) => ` ${letter.toLowerCase()}`)}.`,
      );
    }
    deliveryDetails[field] = value.trim();
  }
  const normalizedPhone = deliveryDetails.phone.replace(/[\s()-]/g, "");
  if (!/^(?:(?:\+|00)?92|0)?3\d{9}$/.test(normalizedPhone)) {
    throw new HttpsError("invalid-argument", "Enter a valid Pakistani mobile number.");
  }
  deliveryDetails.phone = normalizedPhone.startsWith("0")
    ? `+92${normalizedPhone.slice(1)}`
    : normalizedPhone.startsWith("3") ? `+92${normalizedPhone}` : normalizedPhone;
  for (const [field, maximum] of [
    ["landmark", 120],
    ["postalCode", 20],
    ["deliveryInstructions", 300],
  ]) {
    const value = input[field] ?? "";
    if (typeof value !== "string" || value.trim().length > maximum) {
      throw new HttpsError("invalid-argument", `Enter a valid ${field}.`);
    }
    deliveryDetails[field] = value.trim();
  }
  deliveryDetails.country = "Pakistan";
  const fullAddress = [
    deliveryDetails.address,
    deliveryDetails.area,
    deliveryDetails.city,
    deliveryDetails.province,
    ...(deliveryDetails.postalCode ? [deliveryDetails.postalCode] : []),
    deliveryDetails.country,
  ].join(", ");

  const uid = request.auth.uid;
  const cartRef = db.collection("users").doc(uid).collection("cart");
  const orderRef = db.collection("orders").doc();
  const result = await db.runTransaction(async (transaction) => {
    const cartSnapshot = await transaction.get(cartRef);
    if (cartSnapshot.empty) {
      throw new HttpsError("failed-precondition", "Your cart is empty.");
    }
    if (cartSnapshot.size > 100) {
      throw new HttpsError(
        "failed-precondition",
        "Your cart has too many distinct products for one order.",
      );
    }

    const products = [];
    for (const cartItem of cartSnapshot.docs) {
      products.push(await transaction.get(
        db.collection("products").doc(cartItem.id),
      ));
    }

    const orderItems = [];
    let total = 0;
    let itemCount = 0;
    const inventoryWrites = [];

    for (let index = 0; index < cartSnapshot.docs.length; index += 1) {
      const cartItem = cartSnapshot.docs[index];
      const productSnapshot = products[index];
      const cartData = cartItem.data();
      const quantity = cartData.quantity;

      if (!productSnapshot.exists || productSnapshot.data().isActive !== true) {
        throw new HttpsError(
          "failed-precondition",
          "A product in your cart is no longer available.",
        );
      }
      const product = productSnapshot.data();
      const stock = product.stock;
      if (!Number.isInteger(stock) || stock < 0) {
        throw new HttpsError(
          "failed-precondition",
          `${product.name || "A product"} has invalid inventory data. Please contact support.`,
        );
      }
      if (!Number.isInteger(quantity) || quantity < 1 || quantity > stock) {
        throw new HttpsError(
          "failed-precondition",
          `${product.name || "A product"} has insufficient stock.`,
        );
      }
      if (typeof product.price !== "number" || product.price < 0) {
        throw new HttpsError("internal", "A product has an invalid price.");
      }

      const lineTotal = Math.round(product.price * quantity * 100) / 100;
      total = Math.round((total + lineTotal) * 100) / 100;
      itemCount += quantity;
      orderItems.push({
        productId: productSnapshot.id,
        name: product.name || "",
        imageUrl: product.imageUrl || "",
        unitPrice: product.price,
        quantity,
        lineTotal,
      });

      const inventoryRef = db.collection("inventoryHistory").doc();
      inventoryWrites.push({
        productRef: productSnapshot.ref,
        inventoryRef,
        oldStock: stock,
        newStock: stock - quantity,
        productId: productSnapshot.id,
        quantity,
      });
    }

    for (const write of inventoryWrites) {
      transaction.update(write.productRef, {
        stock: write.newStock,
        updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.create(write.inventoryRef, {
        productId: write.productId,
        change: -write.quantity,
        previousStock: write.oldStock,
        newStock: write.newStock,
        reason: "order",
        orderId: orderRef.id,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    transaction.create(orderRef, {
      userId: uid,
      items: orderItems,
      itemCount,
      subtotal: total,
      shipping: 0,
      total,
      address: fullAddress,
      deliveryDetails,
      paymentMethod: "cash_on_delivery",
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    for (const cartItem of cartSnapshot.docs) {
      transaction.delete(cartItem.ref);
    }
    return {orderId: orderRef.id, total};
  });

  return result;
});
