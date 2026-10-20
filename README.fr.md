# TerminalPinch

**Pincez pour zoomer dans le terminal de votre Mac : changez la taille du texte avec deux doigts sur le trackpad, sans redimensionner la fenêtre.**

Une petite app gratuite pour macOS, dans la barre des menus. Compatible Terminal, iTerm2, Ghostty, Warp, kitty et WezTerm.

[English](README.md)

Pincez avec deux doigts sur le trackpad pour agrandir ou réduire le texte, comme dans un navigateur. Contrairement à `⌘ +` / `⌘ -`, la fenêtre garde sa taille.

- Testé avec **Terminal**, **iTerm2**, **Ghostty**, **Warp**, **kitty** et **WezTerm** (devrait aussi marcher avec Alacritty, Hyper et Tabby, pas encore testés)
- Vitesse réglable séparément pour agrandir et pour réduire
- Réglage depuis une **icône dans la barre des menus** ou avec des **commandes Claude Code** (`/pluslent -`, `/plusrapide +`…)
- Disponible en français, anglais, espagnol, italien, allemand, portugais, chinois et japonais (suit la langue du Mac)
- Gratuit et open source

## Installation

**En une ligne** (recommandé, sans avertissement de Gatekeeper) :

```sh
curl -fsSL https://raw.githubusercontent.com/Throover/TerminalPinch/main/install.sh | sh
```

**Ou à la main :**

1. Téléchargez `TerminalPinch-x.y.z.dmg` depuis la [dernière version](../../releases/latest).
2. Ouvrez-le et glissez **TerminalPinch** dans **Applications**.
3. Ouvrez TerminalPinch. La première fois, macOS peut dire que l'app vient d'un développeur non identifié (elle n'est pas notariée par Apple, ce qui coûte 99 $/an) :
   - **macOS 13–14 :** clic droit sur l'app → **Ouvrir** → **Ouvrir**.
   - **macOS 15 et plus :** essayez de l'ouvrir une fois, puis allez dans **Réglages Système → Confidentialité et sécurité** et cliquez sur **Ouvrir quand même**.
4. Suivez la courte configuration : elle demande la seule autorisation nécessaire et vous laisse choisir comment régler la vitesse.

Nécessite macOS 13 Ventura ou plus récent, sur Apple Silicon ou Intel.

## Autorisations

| Autorisation | Pourquoi |
|---|---|
| Accessibilité | pour détecter le pincement, changer la taille du texte dans iTerm2, Ghostty, etc. et remettre la fenêtre à sa taille |
| Automatisation → Terminal | Terminal d'Apple uniquement : pour changer directement la taille de police (demandé au premier pincement) |

TerminalPinch n'écoute que les gestes de pincement. Il ne lit jamais ce que vous tapez et n'a aucun accès au réseau.

## Commandes Claude Code

Si vous utilisez [Claude Code](https://claude.com/claude-code), la configuration peut installer deux commandes, nommées dans votre langue (renommables) :

| Commande | Effet |
|---|---|
| `/pluslent +` | plus lent en agrandissant |
| `/pluslent -` | plus lent en réduisant |
| `/pluslent` | les deux |
| `/plusrapide +`, `/plusrapide -`, `/plusrapide` | pareil, en plus rapide |

Ça marche aussi depuis n'importe quel terminal : `/Applications/TerminalPinch.app/Contents/MacOS/TerminalPinch --adjust slower -`

## FAQ

**Comment zoomer dans le terminal du Mac sans agrandir la fenêtre ?**
Par défaut, `⌘ +` dans Terminal agrandit le texte *et* la fenêtre. TerminalPinch ne change que la taille du texte et garde la fenêtre exactement à sa place et à sa taille.

**Peut-on pincer pour zoomer dans iTerm2, Ghostty, Warp, kitty ou WezTerm ?**
Oui. TerminalPinch ajoute le zoom au pincement à tous ces terminaux, avec le même comportement.

**Est-ce que ça ralentit le Mac ou lit ce que je tape ?**
Non. L'app n'écoute que les pincements du trackpad, consomme quasiment rien et n'a aucun accès au réseau.

## Désinstaller

Quittez TerminalPinch depuis son menu, supprimez-la du dossier Applications, puis si vous voulez lancez `tccutil reset All app.terminalpinch` pour retirer son autorisation.

## Compiler soi-même

```sh
git clone https://github.com/Throover/TerminalPinch.git
cd TerminalPinch
./scripts/build.sh      # → build/TerminalPinch.app et build/TerminalPinch-x.y.z.dmg
```

Seuls les outils en ligne de commande de Xcode sont nécessaires (`xcode-select --install`).

## Soutenir

TerminalPinch est gratuit. S'il vous est utile, vous pouvez le soutenir :

[![Soutenir sur Ko-fi](https://img.shields.io/badge/Ko--fi-Offrir%20un%20caf%C3%A9-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/throover)
[![Soutenir sur Liberapay](https://img.shields.io/badge/Liberapay-Faire%20un%20don-F6C915?logo=liberapay&logoColor=black)](https://liberapay.com/Throover)

- **Ko-fi** : don ponctuel ou mensuel
- **Liberapay** : don récurrent, géré par une association à but non lucratif

## Licence

MIT
