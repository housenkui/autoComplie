#! bin/bash
#我的简书:http://www.jianshu.com/p/e9b3fba1bf56
#Use:命令行进入项目根目录直接执行 sh build.sh即可在桌面生成ipa安装包

#注意:使用本脚本上传到fir.im需要满足以下环境:一. ruby版本>1.9.3 (查看当前ruby版本 ruby -v) 二. ruby安装完毕,安装fir.im命令行插件 (gem install fir-cli)


export LC_ALL=zh_CN.GB2312;
export LANG=zh_CN.GB2312

#一些路径的切换：切换到你的工程文件目录---------
projectPath=$(cd `dirname $0`; pwd)
cd ..
cd $projectPath

###############设置需编译的项目配置名称
buildConfig="Release" #编译的方式,有Release,Debug，自定义的AdHoc等

##########################################################################################
##############################以下部分为自动生成部分，不需要手动修改############################
##########################################################################################
#项目名称
projectName=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`
echo "项目名称:$projectName"
projectDir=`pwd` #项目所在目录的绝对路径
echo $projectDir
wwwIPADir=~/Desktop/$projectName-IPA #ipa，icon最后所在的目录绝对路径
isWorkSpace=true  #判断是用的workspace还是直接project，workspace设置为true，否则设置为false

echo "~~~~~~~~~~~~~~~~~~~开始编译~~~~~~~~~~~~~~~~~~~"
if [ -d "$wwwIPADir" ]; then
echo $wwwIPADir
echo "文件目录存在"
else
echo "文件目录不存在"
mkdir -pv $wwwIPADir
echo "创建${wwwIPADir}目录成功"
fi

###############进入项目目录
cd $projectDir
rm -rf ./build
buildAppToDir=$projectDir/build #编译打包完成后.app文件存放的目录

###############获取版本号,bundleID
infoPlist="$projectName/*-Info.plist"
bundleVersion=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $infoPlist`
bundleIdentifier=`/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" $infoPlist`
bundleBuildVersion=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $infoPlist`

###############开始编译app
if $isWorkSpace ; then  #判断编译方式
echo  "开始编译workspace...."
xcodebuild  -workspace $projectName.xcworkspace -scheme $projectName  -configuration $buildConfig clean build SYMROOT=$buildAppToDir
else
echo  "开始编译target...."
xcodebuild  -target  $projectName  -configuration $buildConfig clean build SYMROOT=$buildAppToDir
fi
#判断编译结果
if test $? -eq 0
then
echo "~~~~~~~~~~~~~~~~~~~编译成功~~~~~~~~~~~~~~~~~~~"
else
echo "~~~~~~~~~~~~~~~~~~~编译失败~~~~~~~~~~~~~~~~~~~"
exit 1
fi

###############开始打包成.ipa
ipaName=`echo $projectName | tr "[:upper:]" "[:lower:]"` #将项目名转小写
findFolderName=`find . -name "$buildConfig-*" -type d |xargs basename` #查找目录
appDir=$buildAppToDir/$findFolderName/  #app所在路径


outPath=$projectPath/temp
#####检测outPath路径是否存在
if [ -d "$outPath" ]; then
echo $outPath
echo "文件目录存在"
else
echo "文件目录不存在"
mkdir -pv $outPath
echo "创建${outPath}目录成功"
fi

#sudo chmod -R 777 $outPath

echo "开始打包$projectName.app成$projectName.ipa....."

xcrun -sdk iphoneos -v PackageApplication $appDir/$projectName.app  -o $outPath/$projectName.ipa

###############开始拷贝到目标下载目录
#检查文件是否存在
if [ -f "$outPath/$ipaName.ipa" ]
then
echo "打包$ipaName.ipa成功."
else
echo "打包$ipaName.ipa失败."
exit 1
fi

Export_Path=$wwwIPADir/$projectName$(date +%Y%m%d-%H:%M:%S).ipa
cp -f -p $outPath/$ipaName.ipa $Export_Path   #拷贝ipa文件
echo "复制$ipaName.ipa到${wwwIPADir}成功"
rm -rf $outPath
rm -rf ./build
echo "~~~~~~~~~~~~~~~~~~~结束编译，处理成功~~~~~~~~~~~~~~~~~~~"

rm -rf $buildAppToDir
rm -rf $projectDir/tmp


