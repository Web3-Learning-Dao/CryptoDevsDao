# CryDevsDAO
> CryDevsDAO是一个可以应用于公司，组织，董事会的基础治理设施，基于NFT来对DAO成员进行描述，分类包括：投资人NFT，贡献者NFT，普通成员NFT。并且由国库对所有资产进行管理，由州长投票模式对不同身份的NFT行驶投票权利。

# 核心概念
CryDevsDAO核心是使用NFT对个人信息进行描述，类似于v神在soulbound中提出的个人身份标签概念，当DAO应用在公司组织中，可以使用NFT来标识管理者和技术人员，给予他们不同的权重，来对决策进行投票治理。或者可以描述创始团队，投资人团队，股份持有人，以分配相应的权重。
在DAO项目活动中，NFT可以分类描述不同投资行为：ICO,IDO，众筹等投资方式，对不同投资人进行投票权重分配，以及Token分配。
不管怎样，基于这种模式下我们可以想象出更多的应用场景。

# 代码结构
CryptoDevsDao核心代码是使用`openzeppelin`合约库进行开发，提供了丰富的合约权限管理，合约安全接口以及基于ERC20,ERC721的投票权重功能，在`openzeppelin Governance`中实现了州长投票治理模式，它可以轻松的实现，Token和NFT的投票权重，以及提案机制，极大的降低了开发的难度，提高合约的安全性。
* `Access Control`实现了合约成员权限的管理。
* `Pausable`实现了合约由授权账户触发的紧急停止机制，保障合约安全
* `ERC20/ERC721 Votes`扩展 ERC20/ERC721 以支持由Token生成的投票和委托
* `Governor` 提供了投票治理的逻辑功能实现，包括从Token中获取投票权重，实现简单的投票和提案机制，提供了时间锁功能

> ## core
>核心代码，实现了NFT/token，国库和州长治理合约逻辑
>> ### CryptoDevsNFT
>>实现了NFT的发布，并且提供三种不同的mint模式：创始人NFTmint>>(只能由admin用户进行mint)，白名单NFTmint，publicNFTmint。
>> ### CryptoDevsToken
>> 实现了Token的发布，并且在创建之后将放弃合约管理权，并且移交到国库合约。
>> ### Governor
>> 治理合约，允许使用ERC721和ERC20权重进行投票，对不同类型的投票治理将创建不同的治理合约，目前支持NFT(1:1)投票治理和Token权重投票治理。
>> ### Treasury 
>> 国库治理合约，在初始化完成后，所有的合约权限都将移交到国库合约，国库管理了Token的交易，并且提供了投资接口，可以提供投资者参与投资，并且由投资者相应的ETH权重来transfer相应的Token和颁发NFT身份标识。
---

> ## interface
>对外接口文件
---

> ## libraries
> 合约库文件
>> * **DataTypes** 数据结构合约
>> * **Errors** 错误处理合约
>> * **Events** 事件合约
---

> ## 业务代码
>> * **Whitelist** 白名单功能实现，分别使用mapping和merkle 两种方式，merkle需要链下生成数据，优点是减少了合约储存空间。
>> * **CryptoDevsEntrance** 工程入口合约，可以根据业务需要创建相对应得合约模块，并且将放弃所有权移交到国库。

# 后期规划 
实现module合约，支持导入和销毁新增功能业务合约，并且支持是否交给国库管理。

