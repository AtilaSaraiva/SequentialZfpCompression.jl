using SequentialZfpCompression
using Documenter

DocMeta.setdocmeta!(SequentialZfpCompression, :DocTestSetup, :(using SequentialZfpCompression); recursive=true)

makedocs(;
    modules=[SequentialZfpCompression],
    authors="Átila Saraiva Quintela Soares",
    repo="https://github.com/AtilaSaraiva/SequentialZfpCompression.jl/blob/{commit}{path}#{line}",
    sitename="SequentialZfpCompression.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://AtilaSaraiva.github.io/SequentialZfpCompression.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/AtilaSaraiva/SequentialZfpCompression.jl",
    devbranch="main",
)
