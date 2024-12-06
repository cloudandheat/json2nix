# Quotes string if it contains anything other than alphanumeric, dash or underscore
def quote_key [] {
    let key = $in

    if (($key | find -r "^[a-zA-Z0-9-_]+$") == null) {
        $'"($key)"'
    } else {
        $key
    }
}

# Converts table data into Nix.
export def "to nix" []: any -> string {
    let value = $in
    match ($value | describe -d | get type) {
        nothing|string => ($value | to json)
        int|float => (if ($value < 0) {$"\(($value)\)"} else {$value})
        table|list => ($value | each {|v| $v | to nix | $"($in)"} | to text | $"[($in)]")
        record => ($value | transpose k v | each {|it| $"($it.k | quote_key) = ($it.v | to nix);"} | to text | $"{($in)}")
        $e => (error make {msg: $"Unknown type ($e)", })
    }
}
