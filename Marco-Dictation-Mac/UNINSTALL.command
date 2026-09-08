#!/bin/bash
# Marco Dictation for macOS : undo. Turns Apple Dictation back off. Nothing else was installed.
defaults write com.apple.HIToolbox AppleDictationAutoEnable -int 0
defaults write com.apple.assistant.support "Dictation Enabled" -bool false
en=$(defaults read com.apple.assistant.support "Dictation Enabled" 2>/dev/null)
if [ "$en" = "0" ]; then printf "\033[32m[OK]\033[0m Dictée désactivée. Rien d'autre à retirer.\n"; else printf "\033[31m[!!]\033[0m Lecture inattendue : %s\n" "$en"; fi
printf "Les langues cochées restent dans Réglages > Clavier > Dictée (sans effet quand la dictée est off).\n"
