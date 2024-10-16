# json2nix

A json/yaml/toml to nix converter written in Haskell.
You can use this easily with a flake.
Unformatted json is also supported.

## Usage

If you have something like this:

```
{
    "name": "Alice",
    "age": 21,
    "length_in_meters": 1.8,
    "best_friends": [
        {
            "name": "bob",
            "age": 19,
        },
        {
            "name": "Sem",
            "age": 19,
        }
    ],
    "favorite_movie": null,
    "(some)%wild;key": 5
}
```

And you want something like this:

```nix
{
  name = "Alice";
  age = 21;
  length_in_meters = 1.8;
  best_friends = [
    {
      name = "bob";
      age = 19;
    }
    {
      name = "Sem";
      age = 19;
    }
  ];
  favorite_movie = null;
  "(some)%wild;key" = 5;
}
```

You can do so by enabling nix flakes and run the following command in your shell:

```shell
nix run github:cloudandheat/json2nix [inputfile] [output]
```

Both arguments may be omitted or set to "-" in which case json2nix will read from stdin resp. write to stdout.

## YAML and TOML

By virtue of [yq](https://github.com/kislyuk/yq), this flake also contains two packages `yaml2nix` and `toml2nix` that can be used just like `json2nix`:

```shell
nix run github:cloudandheat/json2nix#yaml2nix [inputfile] [output]
```

```shell
nix run github:cloudandheat/json2nix#toml2nix [inputfile] [output]
```


## Contributing

If you find a bug please submit [an issue](https://github.com/sempruijs/json2nix/issues) or [pull request](https://github.com/sempruijs/json2nix/pulls).

MIT license


