# Gestion des soumissions

Outil interne pour traiter les soumissions (appels d'offres / demandes de prix construction) : constitution de
lots par corps de métier, sourcing de fournisseurs par catégorie, e-mails de demande de prix groupés, et
dashboard de suivi des offres.

Cette version web pose les **fondations** : authentification, gestion des soumissions/lots/fournisseurs/suivi.
L'extraction PDF automatique du prototype original (détection de zones surlignées, titres de chapitres CFC) est
prévue pour une itération suivante — voir l'onglet "1. Extraction" de l'app, qui permet en attendant la création
manuelle des lots.

## Structure

- `backend/` — API Express + TypeScript + Prisma (SQLite en dev)
- `frontend/` — App React + TypeScript (Vite)

## Démarrage

### Backend

```bash
cd backend
npm install
cp .env.example .env
npx prisma migrate dev
npm run dev   # http://localhost:4000
```

### Frontend

```bash
cd frontend
npm install
npm run dev   # http://localhost:5173, proxy /api vers le backend
```

Ouvrir http://localhost:5173, créer un compte, puis créer une soumission.

## Fonctionnalités

- **Mes soumissions** : créer/ouvrir/supprimer des soumissions, informations projet (contact, date limite,
  lien documents).
- **Lots & e-mails** : créer des lots (manuellement pour l'instant), suggestion automatique de fournisseurs par
  catégorie (base sourcing ~700 fournisseurs), validation/rejet des suggestions, ajout de fournisseurs
  personnalisés, génération de l'e-mail de demande de prix groupé (template Induni).
- **Dashboard de suivi** : par lot × fournisseur, statut, montants, date de relance, e-mail de relance,
  sélection de l'offre retenue, export CSV.
