use std repeat

# Quotes and escapes string
def escape_string []: string -> string {
    to json | str replace -a `${` `\${`
}

# Quotes and escapes string only if it contains anything other than alphanumeric, dash or underscore
def escape_key []: string -> string {
    let key = $in

    if (($key | find -r `^[a-zA-Z_][a-zA-Z_0-9-]*$`) == null) {
        $key | escape_string
    } else {
        $key
    }
}

# Prepends the argument to each line of the input
def indent_lines [indent: string]: string -> string {
    lines | each {|line| $"($indent)($line)"} | str join "\n"
}

# Converts structured data into Nix.
export def "to nix" [
    --raw (-r) # remove all unnecessary whitespace
    --indent (-i): number = 2 # specify indentation width
    --tabs (-t): number # specify indentation tab quantity
    --strip-outer-bracket # strip the brackets of the outermost list or attribute set, so the result can be pasted verbatim into an existing list / attrset
    --prefix: list<string> = []
    --path-notation (-p) # Use path notation if an attribute set only contains a single value
    ]: any -> string {
    let value = $in

    let list_sep = if ($raw) {" "} else {"\n"}
    let attr_sep = if ($raw) {""} else {"\n"}
    let brac_sep = if ($raw or $strip_outer_bracket) {""} else {"\n"}
    let attr_eq_sep = if ($raw) {""} else {" "}

    let list_lbrac = if ($strip_outer_bracket) {""} else {"["}
    let list_rbrac = if ($strip_outer_bracket) {""} else {"]"}
    let attr_lbrac = if ($strip_outer_bracket) {""} else {"{"}
    let attr_rbrac = if ($strip_outer_bracket) {""} else {"}"}

    let to_nix = {|prefix, strip=false| to nix --raw=$raw --indent=$indent --tabs=$tabs --path-notation=$path_notation --strip-outer-bracket=$strip --prefix=$prefix }

    let indentation = (match [$raw, $indent, $tabs, $strip_outer_bracket] {
        [_, _, _, true] => ("")
        [true, _, _, _] => ("")
        [false, $i, null, _] => (" " | repeat $i)
        [false, _, $t, _] => ("\t" | repeat $t)
    } | str join)

    match ($value | describe -d | get type) {
        nothing|bool => ($value | to json)
        
        string => ($value | escape_string)

        int|float => (if ($value < 0) {$"\(($value)\)"} else {$value})

        table|list => (
            $value | each {|v|
                $v | do $to_nix [] | $"($in)"
            } | str join $list_sep | indent_lines $indentation | $"($list_lbrac)($brac_sep)($in)($brac_sep)($list_rbrac)"
        )

        record => (
            $value | transpose k v | each {|it|
                if ( $path_notation and (($it.v | describe -d | get type) == "record") and (($it.v | transpose | length) == 1)) {
                    $it.v | do $to_nix ($prefix | append $it.k) true
                } else {
                    $"($prefix | append $it.k | each {|k| $k | escape_key} | str join ".")($attr_eq_sep)=($attr_eq_sep)($it.v | do $to_nix []);"
                }
            } | str join $attr_sep | indent_lines $indentation | $"($attr_lbrac)($brac_sep)($in)($brac_sep)($attr_rbrac)"
        )

        $e => (print $"ERROR: Unknown type ($e)"; exit )
    }
}
