#!/bin/bash

# Set TERM variable if not set
if [ -z "$TERM" ]; then
    export TERM=xterm-256color
fi

# Reset
Color_Off='\033[0m'     

# Colors
Blue='\033[0;34m'         
Light_Blue='\033[1;34m'   
Green='\033[0;32m'        
Light_Green='\033[1;32m'  
Yellow='\033[1;33m'      
Cyan='\033[0;36m'          
Light_Cyan='\033[1;36m'   
Magenta='\033[0;35m'     
Light_Magenta='\033[1;35m'  
Red='\033[0;31m'           
Light_Red='\033[1;31m'    
White='\033[1;37m'       
Bold='\033[1m'        
 
print_centered() {
    local input="$1"
    local color="$2"
    local term_width=$(tput -T xterm-256color cols)
    local text_width=${#input}
 
    local stripped_input=$(echo -e "$input" | sed 's/\x1b\[[0-9;]*m//g')
    local stripped_width=${#stripped_input}
 
    local pad_width=$(( (term_width - stripped_width) / 2 ))
    local padding=$(printf '%*s' "$pad_width")
 
    echo -e "${padding}${color}${input}${Color_Off}"
}

 
print_blinking() {
    local input="$1"
    local color="$2"
    local term_width=$(tput -T xterm-256color cols)
 
    local stripped_input=$(echo -e "$input" | sed 's/\x1b\[[0-9;]*m//g')
    local stripped_width=${#stripped_input}
     
    local pad_width=$(( (term_width - stripped_width) / 2 ))
    local padding=$(printf '%*s' "$pad_width")
     
    echo -e "${padding}${color}${Bold}${input}${Color_Off}"
}
 
print_separator() {
    local term_width=$(tput -T xterm-256color cols)
    local separator=""
    for ((i=0; i<term_width; i++)); do
        separator="${separator}═"
    done
    echo -e "${Cyan}${separator}${Color_Off}"
}

 
BANNER_ART="
    ____  _______    ____________  _   ___   _______________________    ____
   / __ \/ ____/ |  / / ____/ __ \/ | / / | / / ____/ ____/_  __/   |  /  _/
  / / / / __/  | | / / /   / / / /  |/ /  |/ / __/ / /     / / / /| |  / /  
 / /_/ / /___  | |/ / /___/ /_/ / /|  / /|  / /___/ /___  / / / ___ |_/ /   
/_____/_____/  |___/\____/\____/_/ |_/_/ |_/_____/\____/ /_/ /_/  |_/___/   
                                                                             "

print_banner() {
 
    clear
 
    while IFS= read -r line; do
        print_centered "$line" "$Blue"
        sleep 0.1
    done <<< "$BANNER_ART"
 
    echo ""
    print_separator
    sleep 0.1
 
    print_centered "╔═══════════════════════════════════════════════════════════╗" "$Light_Cyan"
    sleep 0.1
    print_centered "║                                                           ║" "$Light_Cyan"
    sleep 0.1
    print_blinking "║          🚀 DEVCONNECTAI - SOLUÇÃO LICENCIADA 🚀          ║" "$Yellow"
    sleep 0.1
    print_centered "║                                                           ║" "$Light_Cyan"
    print_centered "╚═══════════════════════════════════════════════════════════╝" "$Light_Cyan"
    echo ""
    sleep 0.2
     
    print_centered "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$Green"
    sleep 0.1
    print_centered "✨ ADQUIRA SUA LICENÇA OFICIAL ✨" "$Light_Green"
    sleep 0.1
    print_centered "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$Green"
    echo ""
    sleep 0.2
     
    print_centered "📱 WHATSAPP: +55 (51) 9957-9150" "$Light_Cyan"
    sleep 0.1
    print_centered "🌐 SITE: www.devconnectai.com.br" "$Light_Cyan"
    sleep 0.1
    print_centered "📧 EMAIL: contato@devconnectai.com.br" "$Light_Cyan"
    echo ""
    sleep 0.2
     
    print_centered "✅ Licença Oficial | ✅ Suporte Técnico | ✅ Atualizações" "$Light_Green"
    sleep 0.1
    print_centered "✅ Documentação Completa | ✅ Garantia de Funcionamento" "$Light_Green"
    echo ""
    sleep 0.2
     
    print_centered "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$Red"
    sleep 0.1
    print_centered "⚠️  AVISO LEGAL ⚠️" "$Light_Red"
    sleep 0.1
    print_centered "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$Red"
    echo ""
    sleep 0.1
    print_centered "Compartilhar, vender ou fornecer esta solução" "$Yellow"
    sleep 0.1
    print_centered "sem autorização é crime previsto no artigo 184" "$Yellow"
    sleep 0.1
    print_centered "do Código Penal Brasileiro." "$Yellow"
    echo ""
    sleep 0.1
    print_centered "🔒 PIRATEAR ESTA SOLUÇÃO É CRIME PUNÍVEL POR LEI 🔒" "$Light_Red"
    echo ""
    sleep 0.2
     
    print_centered "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$Cyan"
    sleep 0.1
    print_centered "© 2024 DEVCONNECTAI - Todos os direitos reservados" "$Light_Blue"
    print_centered "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$Cyan"
    echo ""
 
    echo -e "$Color_Off"
}
 
print_banner