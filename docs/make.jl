using Documenter
using RobotDynamics

makedocs(
    sitename = "RobotDynamics",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Introduction" => "index.md",
        "Getting Started" => [
            "models.md",
            "dynamics_evaluation.md"
        ],
        "Documentation" => [
            "discretization.md",
            "knotpoints.md",
            "liemodel.md",
            "rigidbody.md",
            "linearmodel.md",
            "finite_diff.md",
            "dynamics_api.md"   
        ]
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/RoboticExplorationLab/RobotDynamics.jl.git",
)
