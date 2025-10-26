APP_PATH="build/Build/Products/Debug-iphonesimulator/wutzup.app"
BUNDLE_ID="org.archlife.wutzup"

UDIDS=(
  # iPhone 17 Pro
  "884EAB05-C9FB-40A9-B11C-3322953C70B4"
  # iPhone 16 Pro
  "433CFCDA-4B85-4BA7-8E7F-A08DDDE49666"
  # iPhone 17
  "43BAEE5A-D883-43B9-A1E2-176AB4829ADA"
  # iPhone 17 Pro Max
  # "E84BD41D-0764-4718-91AE-B66C1AAFCF51"
)

for UDID in "${UDIDS[@]}"; do
  echo "🚀 Booting simulator $UDID..."
  xcrun simctl boot "$UDID"

  echo "🪟 Opening Simulator UI for $UDID..."
  open -a Simulator --args -CurrentDeviceUDID "$UDID"

  echo "📦 Installing app on $UDID..."
  xcrun simctl install "$UDID" "$APP_PATH"

  echo "▶️ Launching app on $UDID..."
  xcrun simctl launch "$UDID" "$BUNDLE_ID"
done

echo "✅ All simulators launched successfully!"
