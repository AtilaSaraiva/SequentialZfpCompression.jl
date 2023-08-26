using SequentialCompression
using Documenter

DocMeta.setdocmeta!(SequentialCompression, :DocTestSetup, :(using SequentialCompression); recursive=true)

makedocs(;
    modules=[SequentialCompression],
    authors="Átila Saraiva Quintela Soares",
    repo="https://github.com/AtilaSaraiva/SequentialCompression.jl/blob/{commit}{path}#{line}",
    sitename="SequentialCompression.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://AtilaSaraiva.github.io/SequentialCompression.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/AtilaSaraiva/SequentialCompression.jl",
    devbranch="main",
)
