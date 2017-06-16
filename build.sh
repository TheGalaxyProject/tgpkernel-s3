#!/bin/bash
# kernel build script by Tkkg1994 v0.4
# Modified by djb77 / XDA Developers
# Optimized for Samsung Galaxy S3 I9305 Kernels
# Many thanks to @morogoku for his help

# ---------
# VARIABLES
# ---------
BUILD_SCRIPT=2.41
VERSION_NUMBER=$(<build/kernel_version)
ARCH=arm
TOOLCHAIN_PATH=~/android/toolchains/arm-cortexa9_neon-linux-gnueabihf/bin
BUILD_CROSS_COMPILE=$TOOLCHAIN_PATH/arm-cortexa9_neon-linux-gnueabihf-
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
RDIR=$(pwd)
KERNELNAME=TGPKernel.Lite
ZIPLOC=zip
RAMDISKLOC=ramdisk
KERNEL_DEFCONFIG=tgpkernel_defconfig

# ---------
# FUNCTIONS
# ---------
FUNC_CLEAN()
{
make clean
make ARCH=arm distclean
rm -f $RDIR/build/build.log
rm -f $RDIR/arch/$ARCH/boot/Image
rm -f $RDIR/build/boot.img
rm -f $RDIR/build/TGP*.zip
rm -f $RDIR/build/$RAMDISKLOC/image-new.img
rm -f $RDIR/build/$RAMDISKLOC/ramdisk-new.cpio.gz
rm -f $RDIR/build/$RAMDISKLOC/split_img/boot.img-zImage
rm -f $RDIR/build/$ZIPLOC/TGP*.zip
rm -f $RDIR/build/$ZIPLOC/*.img
echo "" > $RDIR/build/$RAMDISKLOC/ramdisk/data/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/ramdisk/dev/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/ramdisk/lib/modules/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/ramdisk/proc/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/ramdisk/sys/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/ramdisk/system/.placeholder
}

FUNC_DELETE_PLACEHOLDERS()
{
find . -name \.placeholder -type f -delete
}

FUNC_BUILD_ZIMAGE()
{
echo "Loading configuration"
echo ""
make -s -j$BUILD_JOB_NUMBER ARCH=$ARCH \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE \
	$KERNEL_DEFCONFIG || exit -1
echo ""
echo "Compiling zImage"
echo ""
make -s -j$BUILD_JOB_NUMBER ARCH=$ARCH \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
echo ""
}

FUNC_BUILD_RAMDISK()
{
find . -name '*.ko' -exec cp -av {} $RDIR/build/ramdisk/ramdisk/lib/modules/ \;
$TOOLCHAIN_PATH/arm-cortexa9_neon-linux-gnueabihf-strip --strip-unneeded $RDIR/build/ramdisk/ramdisk/lib/modules/*.ko
mv -f $RDIR/arch/$ARCH/boot/zImage $RDIR/build/ramdisk/split_img/boot.img-zImage
cd $RDIR/build/ramdisk/
./repackimg.sh
echo SEANDROIDENFORCE >> image-new.img
}

FUNC_BUILD_BOOTIMG()
{
	FUNC_CLEAN
	FUNC_DELETE_PLACEHOLDERS
	(
	FUNC_BUILD_ZIMAGE
	FUNC_BUILD_RAMDISK
	) 2>&1	 | tee -a $RDIR/build/build.log
}

FUNC_BUILD_ZIP()
{
echo ""
echo "Building Zip File"
cd $ZIP_FILE_DIR
zip -gq $ZIP_NAME -r META-INF/ -x "*~"
[ -f "$RDIR/build/$ZIPLOC/boot.img" ] && zip -gq $ZIP_NAME boot.img -x "*~"
if [ -n `which java` ]; then
	echo "Java Detected, Signing Zip File"
	mv $ZIP_NAME old$ZIP_NAME
	java -Xmx1024m -jar $RDIR/build/signapk/signapk.jar -w $RDIR/build/signapk/testkey.x509.pem $RDIR/build/signapk/testkey.pk8 old$ZIP_NAME $ZIP_NAME
	rm old$ZIP_NAME
fi
chmod a+r $ZIP_NAME
mv -f $ZIP_FILE_TARGET $RDIR/build/$ZIP_NAME
cd $RDIR
}

OPTION_1()
{
rm -f $RDIR/build/build.log
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/ramdisk/image-new.img $RDIR/build/boot.img
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your boot.img in the build folder"
echo "You can now find your build.log file in the build folder"
echo ""
exit
}

OPTION_2()
{
rm -f $RDIR/build/build.log
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/ramdisk/image-new.img $RDIR/build/$ZIPLOC/boot.img
ZIP_DATE=`date +%Y%m%d`
ZIP_FILE_DIR=$RDIR/build/$ZIPLOC
ZIP_NAME=$KERNELNAME.I9305.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip file in the build folder"
echo "You can now find your build.log file in the build folder"
echo ""
exit
}

OPTION_0()
{
FUNC_CLEAN
exit
}

# ----------------------------------
# CHECK COMMAND LINE FOR ANY ENTRIES
# ----------------------------------
if [ $1 == 0 ]; then
	OPTION_0
fi
if [ $1 == 1 ]; then
	OPTION_1
fi
if [ $1 == 2 ]; then
	OPTION_2
fi

# -------------
# PROGRAM START
# -------------
rm -rf ./build/build.log
clear
echo "TGPKernel Lite S3 I9305 Build Script v$BUILD_SCRIPT -- Kernel Version: v$VERSION_NUMBER"
echo ""
echo " 0) Clean Workspace"
echo ""
echo " 1) Build TGPKernel Lite boot.img for S3 I9305"
echo " 2) Build TGPKernel Lite boot.img and .zip for S3 I9305"
echo ""
echo " 9) Exit"
echo ""
read -p "Please select an option " prompt
echo ""
if [ $prompt == "0" ]; then
	OPTION_0
elif [ $prompt == "1" ]; then
	OPTION_1
elif [ $prompt == "2" ]; then
	OPTION_2
elif [ $prompt == "9" ]; then
	exit
fi

