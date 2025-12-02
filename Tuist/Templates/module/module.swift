import ProjectDescription

let modulePathAttribute: Template.Attribute = .required("module_path")
let nameAttribute: Template.Attribute = .required("name")

let path = "WWTHN/Sources/Modules/\(modulePathAttribute)"

let template = Template(
    description: "A template for a new feature module",
    attributes: [
        nameAttribute,
        modulePathAttribute,
    ],
    items: [
        .file(path: "\(path)/\(nameAttribute)Feature.swift", templatePath: "stencil/feature.stencil"),
        .file(path: "\(path)/\(nameAttribute)Feature+Action.swift", templatePath: "stencil/feature+action.stencil"),
        .file(path: "\(path)/\(nameAttribute)Feature+State.swift", templatePath: "stencil/feature+state.stencil"),
        .file(path: "\(path)/\(nameAttribute)View.swift", templatePath: "stencil/view.stencil"),
    ]
) 