#!/bin/bash
# Marco Dictation for macOS : one-key voice dictation, French + English.
# No account, no admin password, no subscription. Uses Apple's built-in Dictation.
# What this script changes: 2 user defaults (dictation on, auto-enable) and nothing else.
# Everything Apple refuses to let a script set (languages, shortcut) is done by YOU
# in the pane this script opens, then read back and verified here.

G="\033[32m"; R="\033[31m"; Y="\033[33m"; B="\033[1m"; N="\033[0m"
ok=0; ko=0
step() { if [ "$2" = "1" ]; then printf "  ${G}[OK]${N}  %s\n" "$1"; ok=$((ok+1)); else printf "  ${R}[!!]${N}  %s\n" "$1"; ko=$((ko+1)); fi; }

clear
printf "${B}Marco Dictation pour Mac${N}\n\n"

# 1. macOS version (13 Ventura minimum)
ver=$(sw_vers -productVersion); major=${ver%%.*}
if [ "$major" -lt 13 ]; then
  printf "${R}macOS %s détecté. Il faut macOS 13 (Ventura) ou plus récent.${N}\n" "$ver"; exit 1
fi
printf "macOS %s détecté.\n\n" "$ver"

# 2. Turn dictation on (the part a script CAN do)
defaults write com.apple.HIToolbox AppleDictationAutoEnable -int 1
defaults write com.apple.assistant.support "Dictation Enabled" -bool true

# 3. Open the exact pane for the 2 things a script cannot set
printf "${B}Je t'ouvre les Réglages. Fais ces 3 choses dans le panneau Dictée :${N}\n"
printf "  1. Active l'interrupteur ${B}Dictée${N} (accepte si macOS demande)\n"
printf "  2. ${B}Langues${N} : Modifier, coche ${B}Français${N} et ${B}Anglais${N}\n"
printf "  3. ${B}Raccourci${N} : choisis ${B}Appuyer deux fois sur Contrôle${N}\n\n"
open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension?Dictation" 2>/dev/null \
  || open "/System/Library/PreferencePanes/Keyboard.prefPane"
printf "Quand c'est fait, reviens ici et appuie sur ${B}Entrée${N}... "
read -r _

# 4. Read back and report (verify on the destination, never trust the click)
printf "\n${B}Rapport${N}\n"
step "macOS $ver (13+ requis)" 1
en=$(defaults read com.apple.assistant.support "Dictation Enabled" 2>/dev/null)
[ "$en" = "1" ] && step "Dictée activée (Dictation Enabled = 1)" 1 || step "Dictée PAS activée : interrupteur Dictée dans le panneau" 0
auto=$(defaults read com.apple.HIToolbox AppleDictationAutoEnable 2>/dev/null)
[ "$auto" = "1" ] && step "Auto-enable dictée = 1" 1 || step "Auto-enable dictée absent" 0
langs=$(defaults read com.apple.HIToolbox 2>/dev/null | grep -i -A8 dictation | tr -d '\n')
echo "$langs" | grep -qi "fr" && step "Français présent dans les langues de dictée" 1 || step "Français absent : Langues > Modifier > coche Français" 0
echo "$langs" | grep -qi "en" && step "Anglais présent dans les langues de dictée" 1 || step "Anglais absent : Langues > Modifier > coche Anglais" 0
step "Micro : macOS demandera l'accès au premier usage, accepte" 1
step "Aucun logiciel installé, aucun mot de passe admin demandé" 1

printf "\n"
if [ "$ko" -eq 0 ]; then
  printf "${G}${B}INSTALLATION COMPLÈTE (%s/%s)${N}\n" "$ok" "$((ok+ko))"
else
  printf "${Y}${B}INSTALLATION PARTIELLE (%s/%s) : corrige les lignes rouges, relance INSTALL.command${N}\n" "$ok" "$((ok+ko))"
fi
printf "\n${B}Utilisation${N} : place le curseur dans un champ texte, appuie ${B}2 fois sur Contrôle${N}, parle.\n"
printf "Encore 2 fois Contrôle (ou Échap) pour arrêter.\n"
printf "Langue : clique le petit micro à l'écran pour basculer FR / EN\n"
printf "(sur les macOS récents la dictée bascule toute seule quand les deux langues sont cochées).\n\n"
printf "Envoie une capture de ce rapport à Joseph.\n\n"
open -a TextEdit 2>/dev/null
printf "TextEdit est ouvert pour tester. Ferme cette fenêtre quand tu veux.\n"
