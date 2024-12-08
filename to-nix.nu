use std repeat

# Escapes string if it contains anything other than alphanumeric, dash or underscore
def escape_key [] {
    let key = $in

    if (($key | find -r "^[a-zA-Z_][a-zA-Z_0-9-]+$") == null) {
        $key | to json
    } else {
        $key
    }
}

def indent_lines [indent: string] {
    lines | each {|line| $"($indent)($line)"} | str join "\n"
}

# Converts table data into Nix.
export def "to nix" [
    --raw (-r) # remove all unnecessary whitespace
    --indent (-i): number = 2 # specify indentation width
    --tabs (-t): number # specify indentation tab quantity
    --strip-outer-bracket # strip the brackets of the outermost list or attribute set, so the result can be pasted verbatim into an existing list / attrset
    ]: any -> string {
    let value = $in

    let list_sep = if ($raw) {" "} else {"\n"}
    let attr_sep = if ($raw) {""} else {"\n"}
    let brac_sep = if ($raw) {""} else {"\n"}
    let attr_eq_sep = if ($raw) {""} else {" "}

    let list_lbrac = if ($strip_outer_bracket) {""} else {"["}
    let list_rbrac = if ($strip_outer_bracket) {""} else {"]"}
    let attr_lbrac = if ($strip_outer_bracket) {""} else {"{"}
    let attr_rbrac = if ($strip_outer_bracket) {""} else {"}"}

    let to_nix = {|| to nix --raw=$raw --indent=$indent --tabs=$tabs }

    let indentation = (match [$raw, $indent, $tabs] {
        [true, _, _] => ("")
        [false, $i, null] => (" " | repeat $i)
        [false, _, $t] => ("\t" | repeat $t)
    } | str join)

    match ($value | describe -d | get type) {
        nothing|bool|string => ($value | to json)

        int|float => (if ($value < 0) {$"\(($value)\)"} else {$value})

        table|list => (
            $value | each {|v|
                $v | do $to_nix | $"($in)"
            } | str join $list_sep | indent_lines $indentation | $"($list_lbrac)($brac_sep)($in)($brac_sep)($list_rbrac)"
        )

        record => (
            $value | transpose k v | each {|it|
                $"($it.k | escape_key)($attr_eq_sep)=($attr_eq_sep)($it.v | do $to_nix);"
            } | str join $attr_sep | indent_lines $indentation | $"($attr_lbrac)($brac_sep)($in)($brac_sep)($attr_rbrac)"
        )

        $e => (print $"ERROR: Unknown type ($e)"; exit )
    }
}
