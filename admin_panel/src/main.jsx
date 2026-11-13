import React from "react";
import { createRoot } from "react-dom/client";
import "bootstrap/dist/css/bootstrap.min.css";
import "./styles.css";
import App from "./App.jsx";

if (window.location.pathname !== "/admin") {
  window.history.replaceState(null, "", "/admin");
}

createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
