# requirements
    - Json output of ssh config:
        - https://ssh-config-json.readthedocs.io/en/latest/
        - pip install ssh-config-json
    - jq for parsing json
        - https://formulae.brew.sh/formula/jq
        - brew install jq

# autocomplete search feature
    - add to zsh compinit via fpath where _jsh is located
    - initiate autoload and compinit call afterwards
        ```
        fpath=(~/lab/scripts/jumpScript/ssh/autocomplete $fpath)
        fpath=(~/lab/scripts/jumpScript/directory/autocomplete $fpath)
        autoload -U compinit
        compinit
        ```
