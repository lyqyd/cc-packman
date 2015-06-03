### Packman - Package Management for ComputerCraft

# 1 - Setup

## 1.1 - Manual Installation

To manually install packman, download the `packman` file and place it at /usr/bin/packman in a ComputerCraft device.  Run `/usr/bin/packman fetch` to download the other necessary files.  You will probably want to add /usr/bin to your shell path to make packman easier to use.  All following commands assume that this is done.

## 1.2 - Automatic Pastebin Installation

Run the command `pastebin run 4zyreNZy` to automatically download packman, which will also perform the initial fetch operation and install the `main/easy-shell` package to add /usr/bin to the shell path to make packman easier to use in the future.

# 2 - Installing a Package

Installing packages with packman is quick and simple.  Just run `packman install <package-name> [additional-name(s)]` and packman will fetch the latest versions of the specified packages.  If a package name is unambiguous, you will not need to specify the whole package name.  For instance, installing `lyqydos` is sufficient and will automatically expand to the full package name of `lyqyd/lyqydos`.

# 3 - Removing a Package

Packages can be removed by running `packman remove <package-name> [additional-name(s)]`.

# 4 - Updating a Package

Packages can be updated much like they are installed or removed, with `packman update [package-name(s)]`.  If no packages are specified, the update command will check all installed packages for updates.

# 5 - Viewing Installed Packages

Packman's list command can be used to view installed packages, with `packman list [mask]`.  The optional mask is used as a Lua string pattern, which means it will work with plain text searches as expected.

# 6 - Repositories

## 6.1 - Package Listings

A package listing is used to define packages that packman can install or remove.  Each package listing requires a few pieces of information:

* Name
* Download Type
* Version Number
* Dependencies
* Size

Optional fields that may also be present but are not required include:

* Categories
* Setup Script
* Cleanup Script
* Target Folder

Here is an example package listing that displays all of these fields:

```
name = LyqydOS
	type = github
		author = lyqyd
		repository = LyqydOS
	category = os
	setup = installer setup
	cleanup = installer remove
	dependencies = lyqyd/framebuffer lyqyd/configuration
	target = /LyqydOS
	version = 1.8
	size = 147403
end
```

Note that the package listing _must_ start with the `name` field and end with the `end` keyword.

A group of one or more package listings in a file constitutes a repository.

### 6.1.1 - Name

The name field of a package is important, as it is how users will select your package for installation.  Names must be unique within a given repository, but they do not need to be globally unique.  For stylistic reasons, package maintainers are encouraged to use only a-z and hyphens (-), but any characters other than the forward slash (/) or whitespace characters should work. All names will appear entirely in lower-case to users.

### 6.1.2 - Download Type

There are five download types available to fetch packages with.  Each of these types has two or more arguments that must be specified to complete the download type definition.

* github
  * author
  * repository
* bitbucket
  * author
  * repository
  * branch
* pastebin
  * url
  * filename
* raw
  * url
  * filename
* grin
  * author
  * repository

Most of the arguments are self-explanatory.  Note that the pastebin `url` argument is just the pastebin code, not the entire url.  The `filename` arguments are used to specify the name of the file to be created locally (other download methods simply use the name of the file they are fetching), but should be just a name, not an absolute path.

### 6.1.3 - Version Number

Version numbers must be able to be successfully tonumber()'d for comparison purposes.

### 6.1.4 - Dependencies

The dependency list is a space-separated list of packages that this package depends on.  These should be listed with full package names, not short names (`lyqyd/lyqydos` instead of `lyqydos`). If a package has no dependencies, use `none`.

### 6.1.5 - Categories

The category list is an optional field used to describe the nature of the package.  These should be one-word "tags" that could be used to search for different types of packages, like "os" or "rednet".

### 6.1.6 - Setup and Cleanup Scripts

The setup and cleanup options allow a package to specify a script to be run after installation and before removal, respectively.  The command is formed by appending the whole text of the setup or cleanup field to the target field and then passing the resulting string to shell.run().  This allows for arguments to be passed to the script.

### 6.1.7 - Target Folder

A target folder may be specified to change where files are placed when the package is installed.  By default, the target is /usr/bin.

## 6.2 - Repository List

Packman uses a list of repositories rather than a single central repository to allow software authors to independently maintain and update their own list of packages, so they can publish updates at their own pace.  These repositories are generally named after the person who controls them, and are hosted at a static URL of their choosing.  An example entry from the repository list shows its structure:

    lyqyd https://raw.github.com/lyqyd/cc-packman/master/lyqyd

Each line of the repository list represents a single repository.  The repository name is the first part of the line, followed by the URL that the repository can be fetched from.  The repository name is used as the prefix for the full name for each package inside it.  For instance, every package in the repo from the example above will be named `lyqyd/<name>`.

## 6.3 - Adding a Repository

You can add a repository to the official list by submitting a pull request that adds a line to the [repolist](https://github.com/lyqyd/cc-packman/blob/master/repolist) file with a unique name and a URL pointing to your package list.  New repositories must have a valid package list file at the URL specified to be added.

## 6.4 - Custom Repositories

Custom repositories can be added to a packman install by placing the repository file in /etc/repositories.  Attempting to add the repository to the repolist file on the installed instance will not help, as this file is re-created each time `packman fetch` is run, which will destroy the additional line.  Custom updating repositories is a planned feature.
