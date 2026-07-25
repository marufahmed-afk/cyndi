cask "cyndi" do
  version "0.2.0"
  sha256 "ef99ee8c19292d13de74813bd2ac612a894a19f45c8b996af72a525b269f9612"

  url "https://github.com/marufahmed-afk/cyndi/releases/download/v#{version}/Cyndi.dmg"
  name "Cyndi"
  desc "Sticky notes that live at the notch"
  homepage "https://github.com/marufahmed-afk/cyndi"

  depends_on macos: ">= :sonoma"

  app "Cyndi.app"

  zap trash: [
    "~/Library/Application Support/Cyndi",
    "~/Library/Preferences/com.marufahmed.cyndi.plist",
  ]
end
