# Cahier des charges — WebApp Flutter “Suivi Musculation Maison” (Local‑First + IA avancée)

## Vision
Créer une webapp Flutter **personnelle**, offline‑first, utilisant **l’IA au maximum** pour :
- comprendre automatiquement le programme,
- adapter l’entraînement à la morphologie, au matériel et à la progression,
- automatiser l’entraînement réel (**repos, chronos, enchaînement des séries**) pour éviter d’utiliser le téléphone.

Aucune base de données distante.  
Stockage **100% local** + **export/import JSON complet**.

---

# 1. Rôle central de l’IA (obligatoire)

## 1.1 Parsing intelligent du programme
L’IA doit :
- transformer le texte brut en **JSON structuré fiable**,
- détecter :
  - séances,
  - exercices,
  - séries / reps / durée,
  - règles de repos,
  - logique de progression.

Fallback :
- si IA indisponible → parser déterministe minimal.

## 1.2 Adaptation morphologique automatique
Entrées utilisateur :
- taille, poids
- longueurs relatives (bras longs, fémurs longs…)
- douleurs / limitations
- objectif (force / hypertrophie)

L’IA doit :
- proposer **variantes d’exercices optimales**
- ajuster :
  - fourchettes de reps
  - volume
  - tempo
  - amplitude
- expliquer brièvement les choix.

## 1.3 Progression pilotée par IA
À partir de l’historique :
- détection de plateau
- recommandation automatique :
  - +reps
  - +charge
  - deload léger
  - changement de variante

L’IA agit comme un **coach adaptatif**.

---

# 2. Expérience d’entraînement sans toucher le téléphone

## 2.1 Mode “Workout automatique”
Objectif : **zéro interaction manuelle** pendant la séance.

Fonctionnement :
1. L’utilisateur lance la séance.
2. L’app guide vocalement ou visuellement :
   - exercice courant
   - nombre de reps cible
   - repos restant
3. Passage automatique :
   - série suivante
   - exercice suivant
4. Fin de séance → résumé + suggestion IA.

## 2.2 Gestion intelligente du repos
Repos calculé selon :
- type d’exercice (polyarticulaire vs isolation)
- intensité réelle (RIR saisi ou estimé)
- objectif (force → repos plus long)

Chrono :
- démarre **automatiquement** après validation d’une série
- alerte :
  - vibration
  - son
  - synthèse vocale (option)

## 2.3 Saisie minimale des performances
Réduction d’interaction :
- boutons géants +/‑ pour reps et charge
- **préremplissage automatique** depuis dernière séance
- validation en **1 tap**
- option future :
  - **commande vocale** (“10 reps à 18 kilos”)

---

# 3. Fonctionnalités principales

## 3.1 Programme
- import texte → JSON via IA
- édition visuelle
- substitutions automatiques selon matériel

## 3.2 Exécution séance
- mode plein écran lisible
- auto‑repos
- auto‑enchaînement
- logs rapides

## 3.3 Historique & stats
- PR automatiques
- volume hebdo
- graph progression
- analyse IA :
  - points forts
  - retards musculaires
  - recommandations semaine suivante

## 3.4 Export / Import
Fichier unique :
muscu_backup_YYYY‑MM‑DD.json

Contenu :
- profil
- matériel
- programme
- historique complet
- paramètres IA

Import :
- remplacer
- fusionner intelligent

---

---

# 3.5 Feedback fin de séance (difficulté) — requis

## 3.5.1 Note de difficulté (session rating)
À la fin de chaque séance, l’app doit obligatoirement proposer un écran “Fin de séance” avec :
- **Note de difficulté globale** (échelle au choix, mais fixe dans le produit) :
  - option recommandée : **1–10** (1 = très facile, 10 = maximal)
- **RIR moyen ressenti** (optionnel si tu préfères) : 0–5
- **Commentaires libres** (texte court)
- **Douleurs / inconfort** (checkbox : épaule, coude, genou, dos, autre + champ texte)

Ces champs sont enregistrés dans l’objet `Session`.

## 3.5.2 Utilisation par l’IA (adaptation prochaine séance)
L’IA doit utiliser les feedbacks pour adapter automatiquement la prochaine occurrence de la séance (ou la semaine suivante) :
- Si difficulté **trop élevée** (ex ≥ 8/10) :
  - réduire légèrement la charge cible OU réduire le nombre de séries (1 série en moins) OU allonger le repos
- Si difficulté **trop basse** (ex ≤ 4/10) :
  - accélérer la progression (ajout reps/charge plus agressif) OU réduire le repos
- Si douleurs signalées :
  - proposer substitution d’exercice + ajustement volume / amplitude / tempo
- Conserver une trace de la décision IA (audit) :
  - “reasoning summary” court (1–2 phrases)
  - “actions” structurées (ex : `increase_weight`, `increase_reps`, `change_exercise`, `change_rest`)

## 3.5.3 Contraintes UX
- Écran de feedback fin de séance doit être **1 écran, 10 secondes** max :
  - slider 1–10 + 3 boutons rapides (facile / OK / dur) qui pré-remplissent
  - champs douleur rapides (checkbox)
- Si l’utilisateur quitte sans noter : rappel non bloquant au prochain lancement.



# 4. Architecture technique

## 4.1 Stack Flutter
- Flutter Web
- Riverpod
- go_router

## 4.2 Stockage local
- **Isar** (prioritaire)
- fallback Hive

## 4.3 IA
- appels OpenAI directs avec **clé utilisateur locale**
- validation JSON stricte
- IA désactivable → app reste fonctionnelle



## 4.4 Données — ajout SessionFeedback
Dans le modèle local, ajouter à `Session` :
- `difficultyRating` (int 1–10, nullable jusqu’à fin de séance)
- `avgRir` (int 0–5, nullable)
- `painFlags` (liste de strings)
- `feedbackNote` (string)
- `aiAdjustments` (liste d’objets : date, actions, reasoningSummary, targetWorkoutId)



---

# 5. Écrans

1. Onboarding IA + profil
2. Import programme IA
3. Programme semaine
4. Mode entraînement automatique
4b. Écran fin de séance (note difficulté)
5. Historique
6. Stats + analyse IA
7. Matériel
8. Export / Import
9. Paramètres IA

---

# 6. Étapes de développement

## Phase 1 — Fondations
- projet Flutter
- stockage local
- modèles de données

## Phase 2 — Import IA
- écran import
- appel OpenAI
- validation JSON

## Phase 3 — Player d’entraînement
- chrono auto
- navigation auto
- logs rapides

## Phase 4 — Progression IA
- analyse historique
- recommandations

## Phase 5 — Stats
- PR
- graph
- résumé IA

## Phase 6 — Backup
- export JSON
- import + fusion

---

# 7. Critères de réussite

- Import texte fonctionnel en < 5 s.
- Séance réalisable **sans toucher l’écran** sauf validation série.
- Progression automatique cohérente sur 4 semaines.
- Export/import restaure 100% des données.

---

# 8. Évolutions futures (v2)

- reconnaissance vocale complète
- analyse vidéo posture
- sync cloud optionnelle
- coach conversationnel temps réel

---

**Fin du cahier des charges.**
