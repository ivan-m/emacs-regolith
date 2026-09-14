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

* Test the work stuff works
* Consider these packages:
  - Different modeline settings:
    + mode-line-maker?
  - mode-line-debug
  - popper (make the Chat a popup?)
  - More/better gptel stuff
  - verb-mode instead of restclient
  - no-littering
    - Including auto-save-file-name-transforms for remote files.
  - flymake instead of flycheck
* Get eglot working (e.g. with Haskell) and see if I can get it to work with the AI stuff (e.g.
  Copilot)
* Check if jinx-mode + prog-mode is a good idea (e.g. for Haskell) or
  if I should just use it in text-mode
  - And once I'm happy with jinx, get rid of flyspell references.
* Expand out this README.md to include more information about the configuration and
  how to use it (especially work mode; I really should use a different
  phrase as "mode" is already used in Emacs).
* Audit keybindings for conflicts using `C-h b` and `which-key-show-full-keymap`;
  consider `free-keys` package if adding new bindings.
* Work out how to get `C-c TAB` to be consistent in copilot-chat-mode;
  sometimes it asks me for buffers and other times it just picks a
  random one.
  - Also, why can it sometimes read files I have open and other times
    it can't and needs me to explicitly send a file reference?
  - Get `copilot-quota` to display somewhere.
* Check auto-fill-mode + visual-line-mode interaction in text-mode —
  auto-fill inserts hard line breaks; confirm this is intentional
      alongside visual-line-mode.
