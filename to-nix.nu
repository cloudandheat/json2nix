use std repeat

# Quotes string if it contains anything other than alphanumeric, dash or underscore
def quote_key [] {
    let key = $in

    if (($key | find -r "^[a-zA-Z0-9-_]+$") == null) {
        $'"($key)"'
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
    ]: any -> string {
    let value = $in

    let list_sep = if ($raw) {" "} else {"\n"}
    let attr_sep = if ($raw) {""} else {"\n"}
    let brac_sep = if ($raw) {""} else {"\n"}
    let attr_eq_sep = if ($raw) {""} else {" "}

    let to_nix = {|| to nix --raw=$raw --indent=$indent --tabs=$tabs }

    let indentation = (match [$raw, $indent, $tabs] {
        [true, $i, $t] => ("")
        [false, $i, null] => (" " | repeat $i)
        [false, $i, $t] => ("\t" | repeat $t)
    } | str join)

    match ($value | describe -d | get type) {
        nothing|bool|string => ($value | to json)

        int|float => (if ($value < 0) {$"\(($value)\)"} else {$value})

        table|list => (
            $value | each {|v|
                $v | do $to_nix | $"($in)"
            } | str join $list_sep | indent_lines $indentation | $"[($brac_sep)($in)($brac_sep)]"
        )

        record => (
            $value | transpose k v | each {|it|
                $"($it.k | quote_key)($attr_eq_sep)=($attr_eq_sep)($it.v | do $to_nix);"
            } | str join $attr_sep | indent_lines $indentation | $"{($brac_sep)($in)($brac_sep)}"
        )

        $e => (print $"ERROR: Unknown type ($e)"; exit )
    }
}
