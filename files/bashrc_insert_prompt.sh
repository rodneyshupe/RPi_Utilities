
if [ "$color_prompt" = yes ]; then
    PS1='$(if [[ $? == 0 ]]; then  echo "\[\e[30;46m\] \@ \[\e[m\] \[\e[32m\]\u\[\e[m\]@\[\e[36m\]\h\[\e[m\]:\[\e[0;33m\][\w]\[\e[m\]\$ "; else echo "\[\e[30;46m\] \@ \[\e[m\] \[\e[32m\]\u\[\e[m\]@\[\e[36m\]\h\[\e[m\]:\[\e[0;33m\][\w]\[\e[m\]\[\e[41m\]($?)\[\e[m\]$ "; fi)'
fi
