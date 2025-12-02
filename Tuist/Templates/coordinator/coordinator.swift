import ProjectDescription

let modulePathAttribute: Template.Attribute = .required("module_path")
let rootNameAttribute: Template.Attribute = .required("root_name")
let rootCamelCaseNameAttribute: Template.Attribute = .required("root_camel_case_name")
let nameAttribute: Template.Attribute = .required("name")

let path = "WWTHN/Sources/Modules/\(modulePathAttribute)/Coordinator"

let template = Template(
    description: "A template for a new feature",
    attributes: [
        nameAttribute,
        rootNameAttribute,
        rootCamelCaseNameAttribute,
        modulePathAttribute,
    ],
    items: [
        .file(path: "\(path)/\(nameAttribute)Coordinator.swift", templatePath: "stencil/coordinator.stencil"),
        .file(path: "\(path)/\(nameAttribute)Coordinator+Action.swift", templatePath: "stencil/coordinator+action.stencil"),
        .file(path: "\(path)/\(nameAttribute)Coordinator+State.swift", templatePath: "stencil/coordinator+state.stencil"),
        .file(path: "\(path)/\(nameAttribute)CoordinatorView.swift", templatePath: "stencil/coordinator+view.stencil"),
    ]
)