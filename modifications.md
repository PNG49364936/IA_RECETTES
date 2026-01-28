# Modifications - Recettes IA

## Format des demandes

Pour chaque modification, préciser :
- **Quoi** : ce qui doit être modifié
- **Où** : fichier(s) concerné(s)
- **Ne pas toucher** : ce qui doit rester inchangé
- **Résultat attendu** : description du comportement souhaité

---

## Historique des modifications

### 2026-01-28

#### 1. Ajout des calories par personne
- **Fichier** : `app/services/claude_recipe_service.rb`
- **Modification** : Ajout de `**Calories:** [X kcal par personne]` après `**Difficulté:**` dans le format de recette généré
- **Statut** : OK

#### 2. Onglet "Créer mon compte" en noir
- **Fichier** : `app/views/layouts/application.html.erb`
- **Modification** : Ajout de `style="color: #000;"` sur l'onglet "Créer mon compte"
- **Statut** : OK

#### 3. Spinner de connexion avec barre de progression
- **Fichier** : `app/views/layouts/application.html.erb`
- **Modification** : Ajout d'un spinner animé + barre de progression lors de la soumission des formulaires de connexion et inscription
- **Statut** : OK

#### 4. Suppression de compte par l'administrateur
- **Fichiers** :
  - `app/controllers/admin_controller.rb` (action `destroy_user`)
  - `config/routes.rb` (route DELETE)
  - `app/views/admin/users.html.erb` (bouton supprimer)
- **Modification** : L'admin peut supprimer un utilisateur et toutes ses recettes
- **Statut** : OK

#### 5. Modal "Mon compte" pour utilisateur connecté
- **Fichier** : `app/views/layouts/application.html.erb`
- **Modification** :
  - Ajout lien "Mon compte" dans le header pour utilisateurs connectés
  - Modal avec onglets "Mes informations" et "Supprimer mon compte"
- **Statut** : OK

#### 6. Suppression simplifiée du compte
- **Fichier** : `app/views/layouts/application.html.erb`
- **Modification** : Suppression du champ "taper SUPPRIMER", bouton directement actif
- **Statut** : OK

#### 7. Traductions françaises des dates
- **Fichier** : `config/locales/fr.yml`
- **Modification** : Ajout des `month_names`, `day_names`, `abbr_month_names`, `abbr_day_names`
- **Statut** : OK

#### 8. Bouton "Créer mon compte" texte en blanc
- **Fichier** : `app/views/layouts/application.html.erb`
- **Modification** : Ajout de `color: #fff;` au style du bouton
- **Statut** : OK

#### 9. Header responsive mobile/tablette
- **Fichier** : `app/assets/stylesheets/application.bootstrap.scss`
- **Modification** : Ajout media query `@media (max-width: 991px)` pour afficher le header sur deux lignes (logo puis navigation)
- **Ne pas toucher** : Le header desktop doit rester identique (logo à gauche, navigation à droite sur une ligne)
- **Statut** : OK (après correction)

---

## Prochaines modifications

<!-- Ajouter ici les modifications à faire -->

