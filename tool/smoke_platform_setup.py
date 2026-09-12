from pathlib import Path
import tempfile, plistlib, xml.etree.ElementTree as ET, importlib.util, shutil
src=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('aps', src/'tool/apply_platform_setup.py')
mod=importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
with tempfile.TemporaryDirectory() as d:
    r=Path(d)
    # fake source structure used by patch script
    shutil.copytree(src/'native', r/'native')
    (r/'android/app/src/main').mkdir(parents=True)
    (r/'android/app/src/main/AndroidManifest.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application android:label="salah_focus"></application></manifest>')
    (r/'android/app').mkdir(parents=True, exist_ok=True)
    (r/'android/app/build.gradle.kts').write_text('''android {\n  compileOptions {\n  }\n  defaultConfig {\n  }\n}\n''')
    (r/'ios/Runner').mkdir(parents=True)
    with (r/'ios/Runner/Info.plist').open('wb') as h:
        plistlib.dump({'CFBundleDisplayName':'salah_focus'}, h)
    (r/'ios/Runner/AppDelegate.swift').write_text('// template')
    (r/'ios/Podfile').write_text("platform :ios, '13.0'\n")
    (r/'ios/Runner.xcodeproj').mkdir(parents=True)
    (r/'ios/Runner.xcodeproj/project.pbxproj').write_text('''
/* Begin PBXBuildFile section */
/* End PBXBuildFile section */
/* Begin PBXFileReference section */
/* End PBXFileReference section */
/* Begin PBXVariantGroup section */
/* End PBXVariantGroup section */
97C146F01CF9000F007C117D /* Runner */ = {
    isa = PBXGroup;
    children = ();
};
97C146EC1CF9000F007C117D /* Resources */ = {
    isa = PBXResourcesBuildPhase;
    files = ();
};
knownRegions = (en, Base,);
IPHONEOS_DEPLOYMENT_TARGET = 13.0;
''')
    mod.ROOT=r
    mod.patch_android(); mod.patch_ios()

    manifest=r/'android/app/src/main/AndroidManifest.xml'
    ET.parse(manifest)
    txt=manifest.read_text()
    assert txt.index('<manifest') < txt.index('<uses-permission') < txt.index('<application')
    assert 'android:label="@string/app_name"' in txt
    for token in ['POST_NOTIFICATIONS','SCHEDULE_EXACT_ALARM','ScheduledNotificationReceiver','ScheduledNotificationBootReceiver']:
        assert token in txt, token
    gradle=(r/'android/app/build.gradle.kts').read_text()
    assert 'isCoreLibraryDesugaringEnabled = true' in gradle
    assert 'desugar_jdk_libs:2.1.4' in gradle
    assert (r/'android/app/src/main/res/raw/keep.xml').is_file()
    native_main_activity = r/'native/android/MainActivity.kt'
    generated_main_activity = r/'android/app/src/main/kotlin/com/salahfocus/salah_focus/MainActivity.kt'
    assert generated_main_activity.is_file() == native_main_activity.is_file()
    assert native_main_activity.is_file(), 'System settings bridge must survive bootstrap'
    assert generated_main_activity.read_bytes() == native_main_activity.read_bytes()
    assert (src/'android/app/src/main/kotlin/com/salahfocus/salah_focus/MainActivity.kt').read_bytes() == native_main_activity.read_bytes()

    with (r/'ios/Runner/Info.plist').open('rb') as h:
        info=plistlib.load(h)
    assert info['CFBundleDisplayName']=='My Prayer'
    assert info['CFBundleName']=='My Prayer'
    names = {'en': 'My Prayer', 'de': 'Mein Gebet', 'ar': 'صلاتي',
             'es': 'Mi oración', 'fr': 'Ma prière', 'tr': 'Namazım',
             'ps': 'زما لمونځ', 'ur': 'میری نماز'}
    project_path = r/'ios/Runner.xcodeproj/project.pbxproj'
    project_text = project_path.read_text()
    for language, name in names.items():
        android_name = ET.parse(r/f'android/app/src/main/res/values-{language}/strings.xml')
        assert android_name.find('string').text == name
        ios_name = (r/f'ios/Runner/{language}.lproj/InfoPlist.strings').read_text(encoding='utf-8')
        assert f'CFBundleDisplayName = "{name}";' in ios_name
        assert f'path = {language}.lproj/InfoPlist.strings;' in project_text
        assert language in info['CFBundleLocalizations']
    assert mod.localize_ios_project(project_text) == project_text
    assert 'NSLocationWhenInUseUsageDescription' in info
    assert "platform :ios, '16.0'" in (r/'ios/Podfile').read_text()
    assert 'IPHONEOS_DEPLOYMENT_TARGET = 16.0;' in (r/'ios/Runner.xcodeproj/project.pbxproj').read_text()
    app_delegate = (r/'ios/Runner/AppDelegate.swift').read_text()
    if (r/'native/ios/AppDelegate.swift').is_file():
        assert 'GeneratedPluginRegistrant.register' in app_delegate
    else:
        assert app_delegate == '// template'
print('Platform patch smoke test passed')
