alias composer="php $HOME/composer.phar -vv"
alias gitp="bash $HOME/scripts/gitpush.sh"

alias artis="php artisan -vvv"
alias pserve="php -S localhost:8800"
alias arclearall="artis view:clear && artis route:clear && artis cache:clear && artis twig:clean && artis asset:clear && artis clear-compiled"

alias ace='node ace'

alias perm_d="find . -type d -exec chmod 755 {} +"
alias perm_f="find . -type f -exec chmod 644 {} +"
