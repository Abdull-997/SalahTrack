#!/usr/bin/env python3
from __future__ import annotations

import plistlib
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def patch_android() -> None:
    manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
    text = manifest.read_text(encoding="utf-8")
    permissions = [
        "android.permission.INTERNET",
        "android.permission.ACCESS_COARSE_LOCATION",
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.RECEIVE_BOOT_COMPLETED",
        "android.permission.VIBRATE",
        "android.permission.SCHEDULE_EXACT_ALARM",
        "android.permission.USE_FULL_SCREEN_INTENT",
    ]
    insertion = "\n".join(
        f'    <uses-permission android:name="{permission}" />'
        for permission in permissions
        if permission not in text
    )
    if insertion:
        text, count = re.subn(
            r"(<manifest\b[^>]*>)",
            lambda match: match.group(1) + "\n" + insertion,
            text,
            count=1,
        )
        if count != 1:
            raise RuntimeError("Could not locate <manifest> root element")

    receivers = """
        <!-- Required by flutter_local_notifications for scheduled reminders. -->
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false" />
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
"""
    if "ScheduledNotificationReceiver" not in text:
        text, count = re.subn(
            r"</application\s*>",
            receivers + "    </application>",
            text,
            count=1,
        )
        if count != 1:
            raise RuntimeError("Could not locate </application> element")
    if "com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" not in text:
        text = text.replace(
            "</application>",
            '<receiver\n'
            '            android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver"\n'
            '            android:exported="false" />\n'
            '    </application>',
            1,
        )
    if (ROOT / "native/android/res/mipmap-anydpi-v26/ic_launcher_app.xml").exists():
        text = text.replace('android:icon="@mipmap/ic_launcher"', 'android:icon="@mipmap/ic_launcher_app"')
    text = re.sub(
        r'(<application\b[^>]*\bandroid:label=")[^"]*"',
        r'\1@string/app_name"',
        text,
        count=1,
    )
    if 'android:enableOnBackInvokedCallback=' not in text:
        text = re.sub(
            r'(<application\b[^>]*)(>)',
            r'\1\n        android:enableOnBackInvokedCallback="true"\2',
            text,
            count=1,
        )
    manifest.write_text(text, encoding="utf-8")

    native_resources = ROOT / "native/android/res"
    if native_resources.exists():
        shutil.copytree(native_resources, ROOT / "android/app/src/main/res", dirs_exist_ok=True)

    native_main_activity = ROOT / "native/android/MainActivity.kt"
    if native_main_activity.exists():
        kotlin_target = ROOT / "android/app/src/main/kotlin/com/salahfocus/salah_focus/MainActivity.kt"
        kotlin_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(native_main_activity, kotlin_target)

    gradle = ROOT / "android/app/build.gradle.kts"
    if gradle.exists():
        g = gradle.read_text(encoding="utf-8")
        if "releaseKeystorePropertiesFile" not in g:
            signing = '''import java.io.FileInputStream
import java.util.Properties

val releaseKeystorePropertiesFile = rootProject.file("key.properties")
val releaseKeystoreProperties = Properties()
if (releaseKeystorePropertiesFile.exists()) {
    FileInputStream(releaseKeystorePropertiesFile).use(releaseKeystoreProperties::load)
    val requiredKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    val missingKeys = requiredKeys.filter { releaseKeystoreProperties.getProperty(it).isNullOrBlank() }
    require(missingKeys.isEmpty()) {
        "android/key.properties is missing: ${missingKeys.joinToString()}"
    }
}

'''
            g = signing + g
        if "isCoreLibraryDesugaringEnabled" not in g:
            g = g.replace("compileOptions {", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", 1)
        if "multiDexEnabled = true" not in g:
            g = g.replace("defaultConfig {", "defaultConfig {\n        multiDexEnabled = true", 1)
        if "coreLibraryDesugaring(" not in g:
            g += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
        g = re.sub(
            r'\s*// TODO: Add your own signing config for the release build\.\n'
            r'\s*// Signing with the debug keys for now, so `flutter run --release` works\.\n'
            r'\s*signingConfig = signingConfigs\.getByName\("debug"\)',
            '\n            // Never publish an artifact signed with Flutter\'s debug key.\n'
            '            if (releaseKeystorePropertiesFile.exists()) {\n'
            '                signingConfig = signingConfigs.getByName("release")\n'
            '            }',
            g,
            count=1,
        )
        if 'create("release")' not in g and "buildTypes {" in g:
            signing_config = '''    signingConfigs {
        if (releaseKeystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = releaseKeystoreProperties.getProperty("keyAlias")
                keyPassword = releaseKeystoreProperties.getProperty("keyPassword")
                storeFile = file(releaseKeystoreProperties.getProperty("storeFile"))
                storePassword = releaseKeystoreProperties.getProperty("storePassword")
            }
        }
    }

'''
            g = g.replace("    buildTypes {", signing_config + "    buildTypes {", 1)
        gradle.write_text(g, encoding="utf-8")

    keep = ROOT / "android/app/src/main/res/raw/keep.xml"
    keep.parent.mkdir(parents=True, exist_ok=True)
    keep.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources xmlns:tools="http://schemas.android.com/tools"\n'
        '    tools:keep="@mipmap/ic_launcher" />\n',
        encoding="utf-8",
    )


def localize_ios_project(project: str) -> str:
    """Register launcher names in both existing and fresh Flutter projects."""
    language_ids = {
        'tr': 'B71900100000000000000003',
        'fr': 'B71900100000000000000004',
        'es': 'B71900100000000000000005',
        'en': 'B71900100000000000000006',
        'de': 'B71900100000000000000007',
        'ar': 'B71900100000000000000008',
        'ps': 'B71900100000000000000009',
        'ur': 'B7190010000000000000000A',
        'id': 'B7190010000000000000000B',
        'bn': 'B7190010000000000000000C',
        'pa': 'B7190010000000000000000D',
        'fa': 'B7190010000000000000000E',
        'ms': 'B7190010000000000000000F',
    }

    def upsert(section: str, identifier: str, entry: str) -> None:
        nonlocal project
        pattern = rf'\t\t{identifier} /\*[^\n]*\*/ = \{{.*?\}};'
        if re.search(pattern, project, re.S):
            project = re.sub(pattern, lambda _: entry, project, count=1, flags=re.S)
        else:
            marker = f'/* End {section} section */'
            if marker not in project:
                raise RuntimeError(f'Missing Xcode {section} section')
            project = project.replace(marker, entry + '\n' + marker, 1)

    for language, identifier in language_ids.items():
        upsert('PBXFileReference', identifier,
               f'\t\t{identifier} /* {language} */ = {{isa = PBXFileReference; '
               f'lastKnownFileType = text.plist.strings; name = {language}; '
               f'path = {language}.lproj/InfoPlist.strings; sourceTree = "<group>"; }};')
    children = ''.join(f'\t\t\t\t{identifier} /* {language} */,\n'
                       for language, identifier in language_ids.items())
    upsert('PBXVariantGroup', 'B71900100000000000000002',
           '\t\tB71900100000000000000002 /* InfoPlist.strings */ = {\n'
           '\t\t\tisa = PBXVariantGroup;\n\t\t\tchildren = (\n' + children +
           '\t\t\t);\n\t\t\tname = InfoPlist.strings;\n'
           '\t\t\tsourceTree = "<group>";\n\t\t};')
    upsert('PBXBuildFile', 'B71900100000000000000001',
           '\t\tB71900100000000000000001 /* InfoPlist.strings in Resources */ = '
           '{isa = PBXBuildFile; fileRef = B71900100000000000000002 /* InfoPlist.strings */; };')

    for owner, field, reference in [
        ('97C146F01CF9000F007C117D', 'children',
         'B71900100000000000000002 /* InfoPlist.strings */'),
        ('97C146EC1CF9000F007C117D', 'files',
         'B71900100000000000000001 /* InfoPlist.strings in Resources */'),
    ]:
        pattern = rf'({owner} /\*[^\n]*\*/ = \{{.*?{field} = \()(.*?)(\);)'
        match = re.search(pattern, project, re.S)
        if match is None:
            raise RuntimeError(f'Missing Xcode Runner {field}')
        if reference not in match.group(2):
            project = re.sub(pattern, lambda m: m[1] + m[2] +
                             f'\t\t\t\t{reference},\n\t\t\t' + m[3],
                             project, count=1, flags=re.S)

    def add_regions(match: re.Match) -> str:
        regions = match[1].rstrip()
        for language in language_ids:
            if not re.search(rf'\b{language}\s*,', regions):
                regions += f'\n\t\t\t\t{language},'
        return 'knownRegions = (' + regions + '\n\t\t\t);'
    return re.sub(r'knownRegions = \((.*?)\);', add_regions, project, count=1, flags=re.S)


def configure_ios_notification_entitlements(project: str) -> str:
    """Include Time Sensitive Notifications in every Runner signing configuration."""
    # Anchor on Runner's Info.plist so test and extension targets retain their signing.
    configuration = r'(buildSettings = \{)(.*?)(\n\s*\};)'

    def add_entitlements(match: re.Match) -> str:
        settings = match[2]
        if not re.search(r'INFOPLIST_FILE = "?Runner/Info\.plist"?;', settings):
            return match[0]
        if 'CODE_SIGN_ENTITLEMENTS' in settings:
            settings = re.sub(r'CODE_SIGN_ENTITLEMENTS = [^;]+;',
                              'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;', settings)
        else:
            settings += '\n\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'
        return match[1] + settings + match[3]

    return re.sub(configuration, add_entitlements, project, flags=re.S)


def patch_ios() -> None:
    native_icons = ROOT / "native/ios/AppIcon.appiconset"
    if native_icons.exists():
        shutil.copytree(native_icons, ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset", dirs_exist_ok=True)

    native_app_delegate = ROOT / "native/ios/AppDelegate.swift"
    if native_app_delegate.exists():
        shutil.copy2(native_app_delegate, ROOT / "ios/Runner/AppDelegate.swift")

    native_entitlements = ROOT / "native/ios/Runner.entitlements"
    if native_entitlements.exists():
        entitlement_path = ROOT / "ios/Runner/Runner.entitlements"
        entitlements = {}
        if entitlement_path.exists():
            with entitlement_path.open("rb") as handle:
                entitlements = plistlib.load(handle)
        with native_entitlements.open("rb") as handle:
            entitlements.update(plistlib.load(handle))
        with entitlement_path.open("wb") as handle:
            plistlib.dump(entitlements, handle, sort_keys=False)

    for localization in (ROOT / 'native/ios').glob('*.lproj'):
        shutil.copytree(localization, ROOT / 'ios/Runner' / localization.name, dirs_exist_ok=True)

    info_path = ROOT / "ios/Runner/Info.plist"
    with info_path.open("rb") as handle:
        info = plistlib.load(handle)
    info["CFBundleDisplayName"] = "SalahTrack"
    info["CFBundleName"] = "SalahTrack"
    info["CFBundleLocalizations"] = [
        'ar', 'bn', 'de', 'en', 'es', 'fa', 'fr', 'id', 'ms', 'pa', 'ps', 'tr', 'ur'
    ]
    info["NSLocationWhenInUseUsageDescription"] = (
        "SalahTrack uses your location to calculate local prayer times and Qibla direction."
    )
    with info_path.open("wb") as handle:
        plistlib.dump(info, handle, sort_keys=False)

    podfile = ROOT / "ios/Podfile"
    if podfile.exists():
        p = podfile.read_text(encoding="utf-8")
        if re.search(r"platform :ios, ['\"]\d+\.\d+['\"]", p):
            p = re.sub(r"platform :ios, ['\"]\d+\.\d+['\"]", "platform :ios, '16.0'", p)
        else:
            p = "platform :ios, '16.0'\n" + p
        podfile.write_text(p, encoding="utf-8")

    project = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
    if project.exists():
        p = project.read_text(encoding="utf-8")
        p = re.sub(r"IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;", "IPHONEOS_DEPLOYMENT_TARGET = 16.0;", p)
        p = localize_ios_project(p)
        p = configure_ios_notification_entitlements(p)
        project.write_text(p, encoding="utf-8")


if __name__ == "__main__":
    patch_android()
    patch_ios()
    print("Platform setup applied.")
