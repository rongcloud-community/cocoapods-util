### cocoapods-util介绍
cocoapods-util是一个用于iOS开发提效的一个cocoapods插件。

目前功能有：

1.  pod repo push命令优化
2.  列出当前工程安装的pod组件和pod间的依赖关系
3.  根据podspec文件打包生成二进制
4.  把现有framework生成xcframework
5.  二进制源码链接调试
6.  对工程project.pbxproj文件去除重复引用

# 安装

```
$ gem install cocoapods-util
```

# 使用介绍

```
$ pod util --help
```

![fde10974894037fe52660a72e4057929.png](./assets/a420d39f7d70131c2f65645e699ac9c5.png)

## 1. repo push

推送私有pods仓库的命令，可以跳过验证和跳过编译过程，用于快速发布私有pod。

- 可以通过添加--skip-validate的选项跳过验证步骤。
- 可以通过添加--skip-build的选项跳过编译，但是会验证tag，需要确保tag已存在。

```
$ pod util repo push --help
```

![2947331da6ee0c269dbd6ea073d15d4e.png](./assets/2947331da6ee0c269dbd6ea073d15d4e.png)

该命令是一个提效命令，在推送自己私有仓库的时候可以通过设置--skip-validate选项跳过验证直接推送到私有仓库。

```
$ pod util repo push [yourSpecs] [xxx.podspec] --skip-validate
```

当然你也可以不使用--skip-validate，参数设置和`pod repo push`命令一致

## 2. install list

列出安装的pod库及所有pod之间的依赖关系，可避免频繁查看Podfile.lock查看组件依赖关系。

- 该命令同样为提效命令，可以省去开发者自己去阅读Podfile.lock文件的时间，直接友好的提示开发者
- 可以清晰的看出引用的组件个数、组件依赖、组件分支tag信息、仓库地址等有效信息
- 建议在Podfile文件所在目录执行此命令

```
$ pod util install list --help
```

![f839eae390ea7871a5afecec093dd39c.png](./assets/f839eae390ea7871a5afecec093dd39c.png)

可以在Podfile.lock的同级目录下执行或指定Podfile.lock的路径

```
$ pod util install list --showmore
$ pod util install list ~/Desktop/xxxx/ProjectA/Podfile.lock --showmore
```

![3be13cd62a8450a7c8b2a3fa728984c6.png](./assets/3be13cd62a8450a7c8b2a3fa728984c6.png)


## 3. package

### 介绍

通过podspec文件生成library、framework、xcframework。

- [x] 支持swift
- [x] 支持自定义配置dependency
- [x] 支持排除模拟器
- [x] 支持多平台（ios、osx、watchos、tvos）
- [x] 支持自定义设置工程的build settings（如：排除ios模拟器64位架构、设置支持的架构等）

```
$ pod util package --help
```

![74dd1a40ffa3af3744fdf79384fdebdb.png](./assets/74dd1a40ffa3af3744fdf79384fdebdb.png)

### 示例

#### 生成xcfrmework/framework/library

生成AFNetworking组件的xcframework 进入AFNetworking源码的根目录下，执行下面的命令

```
$ pod util package AFNetworking.podspec --force --local --xcframework

$ pod util package AFNetworking.podspec --force --local --framework

$ pod util package AFNetworking.podspec --force --local --library
```

![d5410dda08a99ee977dd6ca8af98ef74.png](./assets/d5410dda08a99ee977dd6ca8af98ef74.png)

#### 排除模拟器

如果你不需要编译模拟器架构，可以添加--exclude-sim

```
$ pod util package AFNetworking.podspec --force --local --xcframework --exclude-sim
```

#### 平台设置

如果你只需要编译ios架构下的xcframework，可以添加--platforms=ios

```
$ pod util package AFNetworking.podspec --force --local --xcframework --exclude-sim --platforms=ios
```

#### build settings配置

如果你想要做一些build settings特殊配置，可以添加 --build-settings，如设置编译选项排除模拟器arm64架构。理论上来讲，可以像直接操作工程一样，灵活的配置build settings

- 如设置排除arm64位架构

```
$ --build-settings='{"EXCLUDED_ARCHS[sdk=iphonesimulator*]":"arm64"}'
```

- 设置编译swift生成swiftinterface文件

```
$ -build-settings='{"BUILD_LIBRARY_FOR_DISTRIBUTION":"YES"}'
```

- 或者你想设置多个编译选项

```
$ -build-settings='{"EXCLUDED_ARCHS[sdk=iphonesimulator*]":"arm64","BUILD_LIBRARY_FOR_DISTRIBUTION":"YES","VALID_ARCHS":"arm64"}'
```

#### 自定义dependencies

如果你依赖的组件并没有发布到私有仓库，你只是分支依赖！ 如果你依赖的组件和官方源有冲突，你改需要指定source源！ 这时候你可以通过配置`--dependency-config={}`选项指定仓库分支、tag或指定source源。

```
$ --dependency-config='{"PodA":{"git":"xxx","branch":"xxx"},"PodB":{"source":"xxx"}}'
```

## 4. xcframework

### 介绍

可以把现有的framework生成xcframework。

- 内部可以判断是某个平台的framework（如ios、osx、watchos），直接在framework同级目录生成xcframework。

![132d6cec7bc64488deca731d37438cdd.png](./assets/132d6cec7bc64488deca731d37438cdd.png)

### 示例

生成Alamofire的framework

```
$ pod util xcframework Alamofire.framework --force 
```

![e32ea9af2dfae1e3d6b03f0278c33057.png](./assets/e32ea9af2dfae1e3d6b03f0278c33057.png)

![23332974a4941bae97010afb4b4d4c1c.png](./assets/23332974a4941bae97010afb4b4d4c1c.png)

## 5. linksource

源码二进制链接功能。

```
$ pod util linksource --help
```

![b605570c681e5d7877f08458cfd1dbc7.png](./assets/b605570c681e5d7877f08458cfd1dbc7.png)


## 6. uniq

对xcodeproj --> project.pbxproj文件做重复引用的去重。

该命令的来源是我发现工程的.pbxproj文件变得非常大，最大时发现有10M的大小，在执行pod的更新时会卡在install的执行过程`User Project Integration`这一步很长的时间。

我检查了一下这个工程文件，发现这里面有许多重复的引用，这是由于项目长期merge代码的过程中没有很好的解决冲突，保留了相同的引用，所以才有了这个命令。

我尝试对pbxproj文件做了去重，文件大小从10M减小到了1.7M，再执行pod install安装时就不会再卡在`User Project Integration`这一步骤了。

```
$ pod util uniq --help
```

![fbbe647899cc08e867db9238991c1951.png](./assets/fbbe647899cc08e867db9238991c1951.png)

### 示例
```
$ pod util uniq project.xcodeproj
```