# Emacs Regolith

> **_Regolith_** (noun):
>
> > A region of loose unconsolidated rock and dust that sits atop a
> > layer of [Bedrock].

[Bedrock]: https://codeberg.org/ashton314/emacs-bedrock

This is my [new](https://github.com/ivan-m/.emacs.d) Emacs
configuration.  The original plan had been to make it easily
rebase-able on top of Emacs [Bedrock] but that didn't work out when I
realised I was making a _lot_ of changes.  As such, I've completely
taken the contents as a starting point to re-evaluate my Emacs
configuration to see what I wanted to keep, what was no longer
required and what could now be done better.

(Wait, does this mean my Emacs config is loose and unconsolidated?
Sounds about right...)

Hence:

```
░█▀▀░█▄█░█▀█░█▀▀░█▀▀░░░█▀▄░█▀▀░█▀▀░█▀█░█░░░▀█▀░▀█▀░█░█
░█▀▀░█░█░█▀█░█░░░▀▀█░░░█▀▄░█▀▀░█░█░█░█░█░░░░█░░░█░░█▀█
░▀▀▀░▀░▀░▀░▀░▀▀▀░▀▀▀░░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░░▀░░▀░▀

```

(In case you're wondering, the font effects - like that in Emacs
Bedrock - are from Figlet.  I spent way too long working out how it
was done, so in the end I used [this
previewer](https://ascii.rfmariano.it/); Emacs Bedrock uses one of the
"Big Money" fonts, I used "Pagga" for this small version and "DOS
Rebel" for the file-header ones.)

## Changes from Emacs Bedrock

Many, many changes...

Even more than Emacs Bedrock, I found enough goodies in Emacs 30+ that
I'm requiring that here.

Original Bedrock functions/variables have remained as-is.

## Design motivations and focus

In terms of my requirements, I develop in Haskell and a large
motivator for my Emacs bankruptcy was the push to use AI (especially
GitHub Copilot).  I always wanted to migrate away from my legacy
usages of `req-package` - as it no longer seems to be maintained - to
standard `use-package`, especially for use with the [Emacs Overlay for
Nixpkgs](https://github.com/nix-community/emacs-overlay/#extra-library-functionality).

I also have work-specific configuration... but you won't find it here.
Instead, I have various hooks, etc. to load in work-specific files
_if_ they are available, then custom branch solely at work.

## TODO

* Code formatting (reformatter? apheleia?)
* There's an issue using consult instead of isearch where if I found
  what I want and hit `C-g` to exit then the minibuffer full-screen
  buffer stays up and I can't use windmove to switch to it (`C-o`
  works though)
* Test the work stuff works
  - Probably want to have a nicer way to specify package-archives to
    use github mirrors for this
* `tempel` has a list of template files to begin with, so in work mode
  I can prepend a new set of templates to the list.
* Consider these packages:
  - Different modeline settings:
    + mode-line-maker?
  - If I'm going to use nerd-icons, I might as well use more of them
  - mode-line-debug
  - popper (make the Chat a popup?)
  - More/better gptel stuff
  - verb-mode instead of restclient
