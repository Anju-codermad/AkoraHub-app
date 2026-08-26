// Route /produit (SANS l'extension) — Cloudflare Pages redirige
// automatiquement (308) /produit.html vers /produit, et c'est CETTE URL
// que les robots de partage (Facebook/WhatsApp/Messenger) suivent et
// scannent réellement — confirmé via l'outil de débogage de partage
// Facebook (25/08) : og:image retombait sur le logo générique parce que
// seule la route /produit.html avait une fonction branchée, jamais
// /produit. Voir functions/_produit-og.js pour la logique partagée.
export { handleProduitOg as onRequestGet } from "./_produit-og.js";
