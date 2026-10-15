# Kwenta

Sari-sari store simulator for Android. A 2D pixel-art, landscape, touch-based management game built with Godot. Competition project.

## Versions (everyone must match)

- Godot **4.7.2 stable**, standard build (not .NET). Language: GDScript
- JDK **17**
- Android SDK: platform-tools, build-tools 35.0.1, platform android-35, cmake 3.10.2.4988404, NDK 28.1.13356709
- Android package name: `com.uri.kwenta`

Different Godot versions can corrupt scene files, so do not upgrade Godot without telling the group.

## One-time setup (Windows)

### 1. Install the tools

- **Git**: https://git-scm.com/download/win
- **JDK 17**: for example Eclipse Temurin 17 from https://adoptium.net/temurin/releases/?version=17 (pick JDK, x64, `.msi`). Check with `javac -version`. Note the install folder, for example `C:\Program Files\Java\jdk-17`.
- **Godot 4.7.2**: unzip it somewhere permanent, such as `C:\Godot\`. No installer needed.

### 2. Install the Android SDK (command-line tools)

1. Download "Command line tools only" for Windows from https://developer.android.com/studio
2. Create the folder `C:\Android\Sdk\cmdline-tools\latest` and copy the contents of the zip's `cmdline-tools` folder into it (`bin`, `lib`, and so on). This file must exist: `C:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat`
3. In Command Prompt (use your own JDK folder):

```
set "JAVA_HOME=C:\Program Files\Java\jdk-17"
C:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=C:\Android\Sdk --licenses
```

Type `y` for each license, then install the components (this is several GB):

```
C:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=C:\Android\Sdk "platform-tools" "build-tools;35.0.1" "platforms;android-35" "cmake;3.10.2.4988404" "ndk;28.1.13356709"
```

4. Check that `C:\Android\Sdk\platform-tools\adb.exe` exists.

### 3. Get the project

```
mkdir C:\competition
cd C:\competition
git clone <repo URL>
```

Then in the Godot Project Manager click **Import**, choose `project.godot` inside the cloned folder, and open it. The first load takes a moment.

### 4. Connect Godot to the SDK

**Editor → Editor Settings → Export → Android**:
- Android SDK Path: `C:\Android\Sdk`
- Java SDK Path: your JDK 17 folder (the one that contains `bin`)

### 5. Export templates

**Editor → Manage Export Templates**. If it says Offline mode, click **Go Online**. Tick **Android** and **Windows x86_64**, then install.

### 6. Create your Android export preset

Presets are not shared through Git, so everyone creates their own.

1. **Project → Export → Add... → Android**
2. Set **Package → Unique Name** to `com.uri.kwenta`
3. The bottom of the window should show no red errors.

### 7. Set up your phone

1. Settings → About phone → tap **Build number** 7 times.
2. Settings → Developer options → turn on **USB debugging**.
3. Plug in with a data-capable USB cable and tap **Allow** on the phone.
4. Check it is detected:

```
C:\Android\Sdk\platform-tools\adb.exe devices
```

The phone should be listed as `device`.

### 8. Test

Stop any running game, then click **Deploy with Remote Debug** (top right of the editor, next to the play and stop buttons). The test scene should open on your phone in landscape.

## Daily workflow

```
git checkout main
git pull
git checkout -b feature/short-description
# work, then:
git add .
git commit -m "Describe what you changed"
git push -u origin feature/short-description
```

Open a pull request on GitHub and have a teammate review it before merging.

## Team rules

1. **Never commit directly to `main`.** Use a branch and a pull request.
2. **Pull before you start work** each day.
3. **One owner per scene.** Do not edit someone else's `.tscn` file without telling them. Put shared logic in scripts.
4. **Do not change Project Settings** (display, stretch, rendering, input) without telling the group. They live in `project.godot`, which everyone shares, and changes there cause conflicts.
5. **Never commit** `export_presets.cfg`, `.apk`, `.aab`, or `.keystore` files. `.gitignore` already covers these.
6. **Naming:** `snake_case` for files and folders, `PascalCase` for nodes.
7. **Make content data-driven.** Products and customer orders are Resource files in `data/`, not hard-coded.

## Display rules

The project uses a 640x360 base viewport with stretch mode `viewport`, aspect `expand`, scale mode `fractional`, and texture filter `Nearest`. Phones are not all 16:9, so a wider phone shows more of the scene sideways.

- Keep everything the player must tap inside the central 640x360 area.
- Extend backgrounds beyond that area so wide phones do not show empty edges.
- Anchor HUD elements (money, timer) to the screen edges, not to fixed positions.

## Folder structure

```
assets/sprites   products, customers, store, UI
assets/audio
assets/fonts
scenes           main, store, customer, ui
scripts
data             product and order definitions (Resources)
```

## Scene owners

| Area | Owner |
|---|---|
| Store scene and interactions | |
| Customer system and patience timers | |
| Payment and change logic | |
| Game flow (shift, money, day end) | |
| Art and audio | |