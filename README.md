# Marco Dictation (F9)

Dictée vocale en une touche pour Windows (section Mac plus bas). Aucun compte, aucun droit admin, aucun abonnement.

## Installation (2 minutes)

1. Télécharge le zip : **[Marco-Dictation.zip](https://github.com/Joeladai/marco-dictation/releases/latest/download/Marco-Dictation.zip)**
2. Clic droit sur le zip, **Extraire tout**
3. Double-clique sur **INSTALL.bat**
4. Si Windows affiche « Windows a protégé votre ordinateur » : **Informations complémentaires**, puis **Exécuter quand même**
5. Un rapport de 9 lignes s'affiche : tout doit être vert

## Utilisation

- **F9** : dictée en anglais
- **Shift + F9** : dictée en français
- **Échap** : arrête la dictée

Place ton curseur dans n'importe quel champ texte (WhatsApp, Word, un mail), appuie sur la touche, parle.

Si le français ne se lance pas : double-clique sur `INSTALL-SPEECH-LANGUAGES (optional).bat` une fois (installe le pack de reconnaissance vocale française, demande le mot de passe admin).

Détails complets dans `LISEZ-MOI (Francais).txt` du zip. Désinstallation : `UNINSTALL.bat`.

---

One-key voice dictation for Windows. F9 = English, Shift+F9 = French, Esc = stop. See `READ-ME (English).txt` in the zip.

## Mac (macOS 13 Ventura ou plus récent)

1. Télécharge **[Marco-Dictation-Mac.zip](https://github.com/Joeladai/marco-dictation/releases/latest/download/Marco-Dictation-Mac.zip)** et double-clique dessus
2. Clic **droit** sur `INSTALL.command`, **Ouvrir**, puis **Ouvrir** encore (un double-clic simple est bloqué par macOS sur un fichier téléchargé, c'est normal)
3. Le Terminal ouvre les Réglages sur le panneau Dictée : active **Dictée**, coche **Français + Anglais** dans Langues, choisis **Appuyer deux fois sur Contrôle** comme raccourci
4. Reviens dans le Terminal, **Entrée** : rapport vert/rouge

Utilisation : curseur dans un champ texte, **2 fois Contrôle**, parle. 2 fois Contrôle ou Échap pour arrêter. Le petit micro à l'écran bascule FR / EN.

Rien n'est installé : c'est la dictée intégrée d'Apple, le script ne fait qu'activer 2 réglages et vérifier. Désinstallation : `UNINSTALL.command`. Détails dans `LISEZ-MOI (Mac).txt`.
