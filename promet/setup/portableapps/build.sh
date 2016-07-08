#!/bin/bash
basedir=$(pwd)
cd promet/setup/portableapps
echo "Building portableaps stuff..."
TmpDir=$TMP
BuildDir=$TmpDir/software_build
rm -rf $BuildDir
echo "copy to builddir..."
mkdir -p $BuildDir/App/AppInfo
cp -r ./Promet-ERP/* $BuildDir
mkdir -p $BuildDir/App/promet/tools
mkdir -p $BuildDir/App/promet/plugins
# Create Install Dir
unzip -u -d $BuildDir/App/promet $basedir/promet/setup/output/$BUILD_VERSION/prometerp_$TARGET_CPU-$TARGET_OS-$BUILD_VERSION.zip
unzip -u -d $BuildDir/App/promet $basedir/promet/setup/output/$BUILD_VERSION/help-$BUILD_VERSION.zip
unzip -u -d $BuildDir/App/promet $basedir/promet/setup/output/$BUILD_VERSION/importdata-$BUILD_VERSION.zip
unzip -u -d $BuildDir/App/promet $basedir/promet/setup/output/$BUILD_VERSION/messagemanager_$TARGET_CPU-$TARGET_OS-$BUILD_VERSION.zip
unzip -u -d $BuildDir/App/promet $basedir/promet/setup/output/$BUILD_VERSION/plugins_$TARGET_CPU-$TARGET_OS-$BUILD_VERSION.zip
unzip -u -d $BuildDir/App/promet $basedir/promet/setup/output/$BUILD_VERSION/visualtools_$TARGET_CPU-$TARGET_OS-$BUILD_VERSION.zip
rm $BuildDir/App/promet/helpviewer.exe
unzip -u -d $BuildDir/App/promet $basedir/promet/setup/output/$BUILD_VERSION/mailreceiver_$TARGET_CPU-$TARGET_OS-$BUILD_VERSION.zip
echo "building package..."
#cat Appinfo_devel.ini | \
#  sed -b -e "s/VERSION/$Version/g" \
#      -e "s/ARCH/$Arch/g" \
#      -e "s/ARCHFPC/$Archfpc/g" \
#      -e "s/CREATEDDATE/$Date/g" \
#  > $BuildDir/App/AppInfo/appinfo.ini
#rm $BuildDir/App/AppInfo/Launcher/Splash.jpg
cat Appinfo.ini | \
  sed -b -e "s/VERSION/$Version/g" \
      -e "s/ARCH/$Arch/g" \
      -e "s/ARCHFPC/$Archfpc/g" \
      -e "s/CREATEDDATE/$Date/g" \
  > $BuildDir/App/AppInfo/appinfo.ini
cp
/c/PortableApps.comInstaller/PortableApps.comInstaller.exe $BuildDir
cp $BuildDir/*.paf.exe ../output
cd $BuildDir
rm $basedir/../output/promet-erp-$(echo $Version).i386-win32-portable.zip
zip -9 -r $basedir/../output/promet-erp-$(echo $Version).i386-win32-portable.zip Promet-ERP
echo "cleaning up..."

cd $basedir


