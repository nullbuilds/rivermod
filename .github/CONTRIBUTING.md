# Contributor guidelines

This guide outlines the criteria for contributing bugs, requests, and pull requests to the project.

## Reporting bugs

Found a bug? Let us know!

If your bug hasn't [already been logged][all-bugs], feel free to [create a new bug report][bug-report] with as much detail as you can.

## Requesting features

Feature requests are always welcome! 

If your idea hasn't [already been requested][all-enhancements], feel free to [create a new feature request][feature-request] outlining your idea.

## Contributing pull requests

When contributing changes, please ensure the change aligns with the project's goals and meets all of the contribution guidelines outlined below.

### Prohibited contributions

Any contribution which attempts to bypass or document steps to bypass Riverworld's DRM checks or inform users where to obtain illegitimate copies of the game will be rejected.

To honor and respect the rights of copyright holders, contributions which include copyrighted material anywhere in the commit history (including assets from the game) will not be approved unless the asset owner has given explicit consent to do so with a verifiable publicly viewable license compatible with this project's MIT license.

Finally, no audio, visual, or code contributions created using generative AI will be permitted regardless of any copyright release claims made by the tool's provider. Using generative AI to research and inform coding decisions is permitted so long as the output of the generative AI tool is not copied.

### File format documentation

If you've learned something new about one of Riverworld's file formats, please add or update the [format documentation][file-formats].

### Coding conventions

For consistency, please observe Godot's coding style guides and conventions:
* [GDScript][gdscript-style-guide]
* [C#][csharp-style-guide]
* [Shaders][shader-style-guide]

### Testing

When opening a pull request, please include evidence showing the changes have been tested against an original unmodified copy of Riverworld.

[gdscript-style-guide]: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
[csharp-style-guide]: https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_style_guide.html
[shader-style-guide]: https://docs.godotengine.org/en/stable/tutorials/shaders/shaders_style_guide.html
[bug-report]: https://github.com/nullbuilds/rivermod/issues/new?template=bug_report.md
[feature-request]: https://github.com/nullbuilds/rivermod/issues/new?template=feature_request.md
[all-bugs]: https://github.com/nullbuilds/rivermod/issues?q=is%3Aissue%20label%3Atype%2Fbug
[all-enhancements]: https://github.com/nullbuilds/rivermod/issues?q=is%3Aissue%20label%3Atrype%2Fenhancement
[file-formats]: /modding-resources/file-formats
