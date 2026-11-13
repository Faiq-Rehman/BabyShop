const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

const categories = [
  ["diapers", "Diapers"],
  ["clothing", "Clothing"],
  ["baby-food", "Baby Food"],
  ["toys", "Toys"],
  ["skincare", "Skincare"],
  ["accessories", "Accessories"],
];

const products = [
  {
    id: "soft-cotton-onesie",
    name: "Soft Cotton Onesie",
    brand: "Little Sprout",
    categoryName: "Clothing",
    description: "Gentle, breathable cotton for everyday comfort.",
    price: 18.5,
    stock: 24,
  },
  {
    id: "gentle-baby-wipes",
    name: "Gentle Baby Wipes",
    brand: "Pure Nest",
    categoryName: "Diapers",
    description: "Soft fragrance-free wipes for delicate skin.",
    price: 6.99,
    stock: 42,
  },
  {
    id: "organic-oat-cereal",
    name: "Organic Oat Cereal",
    brand: "Tiny Harvest",
    categoryName: "Baby Food",
    description: "Simple organic oats for little appetites.",
    price: 8.25,
    stock: 18,
  },
  {
    id: "woodland-stacking-toy",
    name: "Woodland Stacking Toy",
    brand: "Kind Play",
    categoryName: "Toys",
    description: "A colorful wooden stacking set for curious hands.",
    price: 22,
    stock: 11,
  },
  {
    id: "calendula-baby-balm",
    name: "Calendula Baby Balm",
    brand: "Soft Meadow",
    categoryName: "Skincare",
    description: "A gentle daily moisturizer for sensitive skin.",
    price: 12.75,
    stock: 15,
  },
  {
    id: "silicone-feeding-set",
    name: "Silicone Feeding Set",
    brand: "Little Sprout",
    categoryName: "Accessories",
    description: "A soft-grip bowl and spoon for mealtime.",
    price: 16.4,
    stock: 9,
  },
];

async function seed() {
  const refs = [
    ...categories.map(([id]) => db.collection("categories").doc(id)),
    ...products.map(({id}) => db.collection("products").doc(id)),
  ];

  await db.runTransaction(async (transaction) => {
    const snapshots = [];
    for (const ref of refs) snapshots.push(await transaction.get(ref));
    if (snapshots.some((snapshot) => snapshot.exists)) {
      throw new Error(
        "Seed documents already exist; refusing to overwrite store data.",
      );
    }

    for (let index = 0; index < categories.length; index += 1) {
      const [id, name] = categories[index];
      transaction.create(refs[index], {
        name,
        isActive: true,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    for (let index = 0; index < products.length; index += 1) {
      const product = products[index];
      transaction.create(refs[categories.length + index], {
        ...product,
        imageUrl: "",
        isActive: true,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });
  console.log("Created 6 categories and 6 sample products.");
}

seed().catch((error) => {
  console.error("Could not seed the store:", error.message);
  process.exitCode = 1;
});
