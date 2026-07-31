cask "cyndi" do
  version "0.2.3"
  sha256 "3a5e7f5caa0efa09bf2dbd24c747d2bddef9a4bd4efba8eff791a013c2df8e1a"

  url "https://github.com/marufahmed-afk/cyndi/releases/download/v#{version}/Cyndi.dmg"
  name "Cyndi"
  desc "Sticky notes that live at the notch"
  homepage "https://github.com/marufahmed-afk/cyndi"

  depends_on macos: :sonoma

  app "Cyndi.app"

  zap trash: [
    "~/Library/Application Support/Cyndi",
    "~/Library/Preferences/com.marufahmed.cyndi.plist",
  ]
end
