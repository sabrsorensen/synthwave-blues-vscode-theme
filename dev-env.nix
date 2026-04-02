{ pkgs }:
{
  buildInputs = with pkgs; [
    nodejs
    vsce
    jq
    git
  ];

  shellHook = ''
    echo "Synthwave Blues Development Environment"
    echo "===================================="
    echo "Node.js: $(node --version)"
    echo "npm: $(npm --version)"
    echo ""
    echo "Quick start:"
    echo "  npm install     - Install dependencies"
    echo "  npm run build   - Build extension"
    echo "  vsce package    - Create .vsix package"
    echo "  vsce publish    - Publish to marketplace"
  '';
}
