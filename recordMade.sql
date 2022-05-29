首先需要说明的是在实际中这种做法是没啥意义的，搞这个东西纯属个人兴趣。

做这个例子需要对数据块结构有一定的了解，关于这方面网上有很多说明，就不在一一说明了。


测试表结构如下：

SQL> desc scott.t;
 Name                                      Null?    Type
 ----------------------------------------- -------- ----------------------------
 ID                                                 NUMBER(4)
 NAME                                               VARCHAR2(30)

SQL> select * from scott.t;

        ID NAME
---------- ------------------------------------------------------------
         1 cpic
         2 huateng

SQL> select dbms_rowid.rowid_relative_fno(rowid) file#,dbms_rowid.rowid_block_number(rowid) block# from scott.t;

     FILE#     BLOCK#
---------- ----------
         4        198
         4        198


SQL> select name from v$dbfile where file#=4;

NAME
--------------------------------------------------------------------------------
/test/orcl/orcl/users01.dbf


BBED> set filename '/test/orcl/orcl/users01.dbf'
        FILENAME        /test/orcl/orcl/users01.dbf

BBED> set block 198
        BLOCK#          198

BBED> map /v
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198                                   Dba:0x00000000
------------------------------------------------------------
 KTB Data Block (Table/Cluster)

 struct kcbh, 20 bytes                      @0      
    ub1 type_kcbh                           @0      
    ub1 frmt_kcbh                           @1      
    ub1 spare1_kcbh                         @2      
    ub1 spare2_kcbh                         @3      
    ub4 rdba_kcbh                           @4      
    ub4 bas_kcbh                            @8      
    ub2 wrp_kcbh                            @12     
    ub1 seq_kcbh                            @14     
    ub1 flg_kcbh                            @15     
    ub2 chkval_kcbh                         @16     
    ub2 spare3_kcbh                         @18     

 struct ktbbh, 72 bytes                     @20     
    ub1 ktbbhtyp                            @20     
    union ktbbhsid, 4 bytes                 @24     
    struct ktbbhcsc, 8 bytes                @28     
    b2 ktbbhict                             @36     
    ub1 ktbbhflg                            @38     
    ub1 ktbbhfsl                            @39     
    ub4 ktbbhfnx                            @40     
    struct ktbbhitl[2], 48 bytes            @44     

 struct kdbh, 14 bytes                      @100    
    ub1 kdbhflag                            @100    
    b1 kdbhntab                             @101    
    b2 kdbhnrow                             @102    
    sb2 kdbhfrre                            @104    
    sb2 kdbhfsbo                            @106    
    sb2 kdbhfseo                            @108    
    b2 kdbhavsp                             @110    
    b2 kdbhtosp                             @112    

 struct kdbt[1], 4 bytes                    @114    
    b2 kdbtoffs                             @114    
    b2 kdbtnrow                             @116    

 sb2 kdbr[2]                                @118    

 ub1 freespace[8041]                        @122    

 ub1 rowdata[25]                            @8163   

 ub4 tailchk                                @8188   

BBED> p kdbr
sb2 kdbr[0]                                 @118      8077
sb2 kdbr[1]                                 @120      8063

BBED> p rowdata
ub1 rowdata[0]                              @8163     0x2c
ub1 rowdata[1]                              @8164     0x02
ub1 rowdata[2]                              @8165     0x02
ub1 rowdata[3]                              @8166     0x02
ub1 rowdata[4]                              @8167     0xc1
ub1 rowdata[5]                              @8168     0x03
ub1 rowdata[6]                              @8169     0x07
ub1 rowdata[7]                              @8170     0x68
ub1 rowdata[8]                              @8171     0x75
ub1 rowdata[9]                              @8172     0x61
ub1 rowdata[10]                             @8173     0x74
ub1 rowdata[11]                             @8174     0x65
ub1 rowdata[12]                             @8175     0x6e
ub1 rowdata[13]                             @8176     0x67
ub1 rowdata[14]                             @8177     0x2c
ub1 rowdata[15]                             @8178     0x01
ub1 rowdata[16]                             @8179     0x02
ub1 rowdata[17]                             @8180     0x02
ub1 rowdata[18]                             @8181     0xc1
ub1 rowdata[19]                             @8182     0x02
ub1 rowdata[20]                             @8183     0x04
ub1 rowdata[21]                             @8184     0x63
ub1 rowdata[22]                             @8185     0x70
ub1 rowdata[23]                             @8186     0x69
ub1 rowdata[24]                             @8187     0x63

BBED> x /rnc offset 8163
rowdata[0]                                  @8163   
----------
: 0x2c (KDRHFL, KDRHFF, KDRHFH)
: 0x02
:    2

col    0[2] @8166: 2
col    1[7] @8169: huateng


BBED> x /rnc offset 8177
rowdata[14]                                 @8177   
-----------
: 0x2c (KDRHFL, KDRHFF, KDRHFH)
: 0x01
:    2

col    0[2] @8180: 1
col    1[4] @8183: cpic


从上面可以看到数据块中有2条记录,数据存放在块偏移量8163到8187这几个字节中。

我的测试环境是AIX 平台，endian_format 是BIG的 (如果是little的平台，构造数据的时候需要注意存放顺序)。

构造数据之前需要了解一点基础知识：
下面的信息摘自ORACLE 10G CONCEPTS:

A row fully contained in one block has at least 3 bytes of row header. After the row header information, each row contains column length and data. The column length requires 1 byte for columns that store 250

bytes or less, or 3 bytes for columns that store more than 250 bytes, and precedes the column data. Space required for column data depends on the datatype. If the datatype of a column is variable length, then

the space required to hold a value can grow and shrink with updates to the data.

To conserve space, a null in a column only stores the column length (zero). Oracle does not store data for the null column. Also, for trailing null columns, Oracle does not even store the column length.

普通的一条行记录在数据块中的格式为：

ROW PIECE =   flag( fb 1bytes )  + lock (lb 1bytes ) + cols(cc 1 bytes )  + col0 length (指记录col长度的) + col0 bytes + col1 length + col1 bytes + .........

如果列的长度超过250个字节，ORACLE将会用3个字节来存放长度，否则用1个字节存放长度，不明白的话可以看ORACLE CONCEPTS。

 

下面我们构造一条ID=3,NAME=yanshoupeng的记录。

我们可以根据已有的数据记录来构造记录，只需要改一下列存储的长度及其值即可。


2,huateng 这条记录在数据块中的存储为：

flag(1 byte)  lock byte(1 byte)   cols(1 byte)  存储列1的长度(1 byte)   列1的值(2 bytes)     存储列2的长度 (1 byte)  列2的值(7 bytes)
2c      02                02     02           c103                  07                      68756174656e67


根据上面的信息来构造id=3,name=yanshoupeng的记录。

SQL> select dump(3,16) from dual;

DUMP(3,16)
----------------------------------
Typ=2 Len=2: c1,4

SQL> select dump('yanshoupeng',16) from dual;

DUMP('YANSHOUPENG',16)
--------------------------------------------------------------------------------
Typ=96 Len=11: 79,61,6e,73,68,6f,75,70,65,6e,67

构造后的记录存储在块中的信息如下：
 
flag(1 byte)  lock byte(1 byte)   cols(1 byte)  存储列1的长度(1 byte)   列1的值(2 bytes)     存储列2的长度 (1 byte)  列2的值(11 bytes)
2c      02                02     02           c104                  0b                     79616e73686f7570656e67


下面我们将这些信息写入数据块中：

 

BBED> p rowdata
ub1 rowdata[0]                              @8163     0x2c
ub1 rowdata[1]                              @8164     0x01
ub1 rowdata[2]                              @8165     0x02
ub1 rowdata[3]                              @8166     0x02
ub1 rowdata[4]                              @8167     0xc1
ub1 rowdata[5]                              @8168     0x03
ub1 rowdata[6]                              @8169     0x07
ub1 rowdata[7]                              @8170     0x68
ub1 rowdata[8]                              @8171     0x75
ub1 rowdata[9]                              @8172     0x61
ub1 rowdata[10]                             @8173     0x74
ub1 rowdata[11]                             @8174     0x65
ub1 rowdata[12]                             @8175     0x6e
ub1 rowdata[13]                             @8176     0x67
ub1 rowdata[14]                             @8177     0x2c
ub1 rowdata[15]                             @8178     0x01
ub1 rowdata[16]                             @8179     0x02
ub1 rowdata[17]                             @8180     0x02
ub1 rowdata[18]                             @8181     0xc1
ub1 rowdata[19]                             @8182     0x02
ub1 rowdata[20]                             @8183     0x04
ub1 rowdata[21]                             @8184     0x63
ub1 rowdata[22]                             @8185     0x70
ub1 rowdata[23]                             @8186     0x69
ub1 rowdata[24]                             @8187     0x63


BBED> set offset 8163
        OFFSET          8163

BBED> dump /v count 32
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198     Offsets: 8163 to 8191  Dba:0x00000000
-------------------------------------------------------
 2c010202 c1030768 75617465 6e672c01 l ,......huateng,.
 0202c102 04637069 63f1a106 01       l .....cpic....

 <16 bytes per line>

BBED> set offset -2
        OFFSET          8161

BBED> modify /x 6e67
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets: 8161 to 8191           Dba:0x00000000
------------------------------------------------------------------------
 6e672c01 0202c103 07687561 74656e67 2c010202 c1020463 706963f1 a10601

 <32 bytes per line>

BBED> set offset -2
        OFFSET          8159

BBED> modify /x 7065
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets: 8159 to 8190           Dba:0x00000000
------------------------------------------------------------------------
 70656e67 2c010202 c1030768 75617465 6e672c01 0202c102 04637069 63f1a106

 <32 bytes per line>

BBED> set offset -2
        OFFSET          8157

BBED> modify /x 6f75
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets: 8157 to 8188           Dba:0x00000000
------------------------------------------------------------------------
 6f757065 6e672c01 0202c103 07687561 74656e67 2c010202 c1020463 706963f1

 <32 bytes per line>

BBED> set offset -2
        OFFSET          8155

BBED> modify /x 7368
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets: 8155 to 8186           Dba:0x00000000
------------------------------------------------------------------------
 73686f75 70656e67 2c010202 c1030768 75617465 6e672c01 0202c102 04637069

 <32 bytes per line>

BBED> set offset -2
        OFFSET          8153

BBED> modify /x 616e
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets: 8153 to 8184           Dba:0x00000000
------------------------------------------------------------------------
 616e7368 6f757065 6e672c01 0202c103 07687561 74656e67 2c010202 c1020463

 <32 bytes per line>

BBED> set offset -2
        OFFSET          8151

BBED> modify /x 0b79
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets: 8151 to 8182           Dba:0x00000000
------------------------------------------------------------------------
 0b79616e 73686f75 70656e67 2c010202 c1030768 75617465 6e672c01 0202c102

 <32 bytes per line>

BBED> set offset -2
        OFFSET          8149

BBED> modify /x c104
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets: 8149 to 8180           Dba:0x00000000
------------------------------------------------------------------------
 c1040b79 616e7368 6f757065 6e672c01 0202c103 07687561 74656e67 2c010202

 <32 bytes per line>

BBED> set offset -2
        OFFSET          8147

BBED> modify /x 0202
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets: 8147 to 8178           Dba:0x00000000
------------------------------------------------------------------------
 0202c104 0b79616e 73686f75 70656e67 2c010202 c1030768 75617465 6e672c01

 <32 bytes per line>

BBED> set offset -2
        OFFSET          8145

BBED> modify /x 2c02
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets: 8145 to 8176           Dba:0x00000000
------------------------------------------------------------------------
 2c020202 c1040b79 616e7368 6f757065 6e672c01 0202c103 07687561 74656e67

 <32 bytes per line>

BBED> dump /v count 64
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198     Offsets: 8145 to 8191  Dba:0x00000000
-------------------------------------------------------
 2c020202 c1040b79 616e7368 6f757065 l ,......yanshoupe
 6e672c01 0202c103 07687561 74656e67 l ng,......huateng
 2c010202 c1020463 706963f1 a10601   l ,......cpic....

 <16 bytes per line>

BBED> x /rnc
freespace[8023]                             @8145   
---------------
: 0x2c (KDRHFL, KDRHFF, KDRHFH)
: 0x02
:    2

col    0[2] @8148: 3
col   1[11] @8151: yanshoupeng

 

好了，数据已经构造出来了。但是现在数据还不能用。我们还需要在row directory中增加这条记录的信息。


BBED> p kdbr
sb2 kdbr[0]                                 @118      8077
sb2 kdbr[1]                                 @120      8063


目前row directory中有2条记录的信息，每条记录占用2个字节，存放指向实际数据开始的相对地址。

这个偏移量是通过如下算法实现的：

FOR ASSM

real offset = kdbr[n] +  76 + (itls-1) *24

FOR MSSM

real offset= kdbr[n] + 68  + (itls-1) *24

  

 

本例中采用的ASSM，记录0的偏移量 real offset = kdbr[0] +  76 + (2-1) *24  = 8077 + 76 + 24 = 8177     --struct ktbbhitl[2], 48 bytes            @44   从这里可以看到itls为2

8177也就是记录0的开始位置 如下

BBED> p rowdata
ub1 rowdata[0]                              @8163     0x2c --记录1的开始位置
ub1 rowdata[1]                              @8164     0x01
ub1 rowdata[2]                              @8165     0x02
ub1 rowdata[3]                              @8166     0x02
ub1 rowdata[4]                              @8167     0xc1
ub1 rowdata[5]                              @8168     0x03
ub1 rowdata[6]                              @8169     0x07
ub1 rowdata[7]                              @8170     0x68
ub1 rowdata[8]                              @8171     0x75
ub1 rowdata[9]                              @8172     0x61
ub1 rowdata[10]                             @8173     0x74
ub1 rowdata[11]                             @8174     0x65
ub1 rowdata[12]                             @8175     0x6e
ub1 rowdata[13]                             @8176     0x67
ub1 rowdata[14]                             @8177     0x2c  --记录0的开始位置 8177
ub1 rowdata[15]                             @8178     0x01
ub1 rowdata[16]                             @8179     0x02
ub1 rowdata[17]                             @8180     0x02
ub1 rowdata[18]                             @8181     0xc1
ub1 rowdata[19]                             @8182     0x02
ub1 rowdata[20]                             @8183     0x04
ub1 rowdata[21]                             @8184     0x63
ub1 rowdata[22]                             @8185     0x70
ub1 rowdata[23]                             @8186     0x69
ub1 rowdata[24]                             @8187     0x63


刚刚我们构造的记录3的real offset = 8145,那么相对偏移量就是8045，我们把这个值存放到row directory中。


BBED> set offset 118
        OFFSET          118

BBED> dump /v count 16
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198     Offsets:  118 to  133  Dba:0x00000000
-------------------------------------------------------
 1f8d1f7f 00000100 00c10100 00c10000 l ................

 <16 bytes per line>

BBED> modify /x 1f6d offset +4
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets:  122 to  137           Dba:0x00000000
------------------------------------------------------------------------
 1f6d0100 00c10100 00c10000 00000000

 <32 bytes per line>

BBED> set offset 118
        OFFSET          118

BBED> dump /v count 16
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198     Offsets:  118 to  133  Dba:0x00000000
-------------------------------------------------------
 1f8d1f7f 1f6d0100 00c10100 00c10000 l .....m..........

 <16 bytes per line>

BBED> p kdbr
sb2 kdbr[0]                                 @118      8077
sb2 kdbr[1]                                 @120      8063

BBED> set offset 102
        OFFSET          102

BBED> dump /v count 16
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198     Offsets:  102 to  117  Dba:0x00000000
-------------------------------------------------------
 0002ffff 00161f7f 1f691f69 00000002 l .........i.i....

 <16 bytes per line>

BBED> modify /x 0003
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets:  102 to  117           Dba:0x00000000
------------------------------------------------------------------------
 0003ffff 00161f7f 1f691f69 00000002

 <32 bytes per line>

BBED> set offset 116
        OFFSET          116

BBED> dump /v count 16
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198     Offsets:  116 to  131  Dba:0x00000000
-------------------------------------------------------
 00021f8d 1f7f1f6d 010000c1 010000c1 l .......m........

 <16 bytes per line>

BBED> modify /x 0003
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets:  116 to  131           Dba:0x00000000
------------------------------------------------------------------------
 00031f8d 1f7f1f6d 010000c1 010000c1

 <32 bytes per line>

BBED> p kdbr
sb2 kdbr[0]                                 @118      8077
sb2 kdbr[1]                                 @120      8063
sb2 kdbr[2]                                 @122      8045


可以看到 row directory中的信息构造出来了。


剩下的工作还需要修改可用空间，及其开始偏移量及其结束偏移量。

 

BBED> map /v
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198                                   Dba:0x00000000
------------------------------------------------------------
 KTB Data Block (Table/Cluster)

 struct kcbh, 20 bytes                      @0      
    ub1 type_kcbh                           @0      
    ub1 frmt_kcbh                           @1      
    ub1 spare1_kcbh                         @2      
    ub1 spare2_kcbh                         @3      
    ub4 rdba_kcbh                           @4      
    ub4 bas_kcbh                            @8      
    ub2 wrp_kcbh                            @12     
    ub1 seq_kcbh                            @14     
    ub1 flg_kcbh                            @15     
    ub2 chkval_kcbh                         @16     
    ub2 spare3_kcbh                         @18     

 struct ktbbh, 72 bytes                     @20     
    ub1 ktbbhtyp                            @20     
    union ktbbhsid, 4 bytes                 @24     
    struct ktbbhcsc, 8 bytes                @28     
    b2 ktbbhict                             @36     
    ub1 ktbbhflg                            @38     
    ub1 ktbbhfsl                            @39     
    ub4 ktbbhfnx                            @40     
    struct ktbbhitl[2], 48 bytes            @44     

 struct kdbh, 14 bytes                      @100    
    ub1 kdbhflag                            @100    
    b1 kdbhntab                             @101    
    b2 kdbhnrow                             @102    
    sb2 kdbhfrre                            @104    
    sb2 kdbhfsbo                            @106    
    sb2 kdbhfseo                            @108    
    b2 kdbhavsp                             @110    
    b2 kdbhtosp                             @112    

 struct kdbt[1], 4 bytes                    @114    
    b2 kdbtoffs                             @114    
    b2 kdbtnrow                             @116    

 sb2 kdbr[3]                                @118    

 ub1 freespace[8041]                        @124    

 ub1 rowdata[25]                            @8165   

 ub4 tailchk                                @8188   


BBED> p kdbhfsbo
sb2 kdbhfsbo                                @106      22

BBED> p kdbhfseo
sb2 kdbhfseo                                @108      8063

BBED> p kdbhavsp
b2 kdbhavsp                                 @110      8041

BBED> p kdbhtosp
b2 kdbhtosp                                 @112      8041

BBED> dump /v count 16 offset 106
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198     Offsets:  106 to  121  Dba:0x00000000
-------------------------------------------------------
 00161f7f 1f691f69 00000003 1f8d1f7f l .....i.i........

 <16 bytes per line>

BBED> modify /x 0018 offset 106
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets:  106 to  121           Dba:0x00000000
------------------------------------------------------------------------
 00181f7f 1f691f69 00000003 1f8d1f7f

 <32 bytes per line>

BBED> modify /x 1f6d offset 108
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets:  108 to  123           Dba:0x00000000
------------------------------------------------------------------------
 1f6d1f69 1f690000 00031f8d 1f7f1f6d

 <32 bytes per line>

BBED> modify /x 1f55 offset 110
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets:  110 to  125           Dba:0x00000000
------------------------------------------------------------------------
 1f551f69 00000003 1f8d1f7f 1f6d0100

 <32 bytes per line>

BBED> modify /x 1f55 offset 112
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets:  112 to  127           Dba:0x00000000
------------------------------------------------------------------------
 1f550000 00031f8d 1f7f1f6d 010000c1

 <32 bytes per line>

BBED> map /v
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198                                   Dba:0x00000000
------------------------------------------------------------
 KTB Data Block (Table/Cluster)

 struct kcbh, 20 bytes                      @0      
    ub1 type_kcbh                           @0      
    ub1 frmt_kcbh                           @1      
    ub1 spare1_kcbh                         @2      
    ub1 spare2_kcbh                         @3      
    ub4 rdba_kcbh                           @4      
    ub4 bas_kcbh                            @8      
    ub2 wrp_kcbh                            @12     
    ub1 seq_kcbh                            @14     
    ub1 flg_kcbh                            @15     
    ub2 chkval_kcbh                         @16     
    ub2 spare3_kcbh                         @18     

 struct ktbbh, 72 bytes                     @20     
    ub1 ktbbhtyp                            @20     
    union ktbbhsid, 4 bytes                 @24     
    struct ktbbhcsc, 8 bytes                @28     
    b2 ktbbhict                             @36     
    ub1 ktbbhflg                            @38     
    ub1 ktbbhfsl                            @39     
    ub4 ktbbhfnx                            @40     
    struct ktbbhitl[2], 48 bytes            @44     

 struct kdbh, 14 bytes                      @100    
    ub1 kdbhflag                            @100    
    b1 kdbhntab                             @101    
    b2 kdbhnrow                             @102    
    sb2 kdbhfrre                            @104    
    sb2 kdbhfsbo                            @106    
    sb2 kdbhfseo                            @108    
    b2 kdbhavsp                             @110    
    b2 kdbhtosp                             @112    

 struct kdbt[1], 4 bytes                    @114    
    b2 kdbtoffs                             @114    
    b2 kdbtnrow                             @116    

 sb2 kdbr[3]                                @118    

 ub1 freespace[8021]                        @124    

 ub1 rowdata[43]                            @8145   

 ub4 tailchk                                @8188   


BBED> p rowdata
ub1 rowdata[0]                              @8145     0x2c
ub1 rowdata[1]                              @8146     0x02
ub1 rowdata[2]                              @8147     0x02
ub1 rowdata[3]                              @8148     0x02
ub1 rowdata[4]                              @8149     0xc1
ub1 rowdata[5]                              @8150     0x04
ub1 rowdata[6]                              @8151     0x0b
ub1 rowdata[7]                              @8152     0x79
ub1 rowdata[8]                              @8153     0x61
ub1 rowdata[9]                              @8154     0x6e
ub1 rowdata[10]                             @8155     0x73
ub1 rowdata[11]                             @8156     0x68
ub1 rowdata[12]                             @8157     0x6f
ub1 rowdata[13]                             @8158     0x75
ub1 rowdata[14]                             @8159     0x70
ub1 rowdata[15]                             @8160     0x65
ub1 rowdata[16]                             @8161     0x6e
ub1 rowdata[17]                             @8162     0x67
ub1 rowdata[18]                             @8163     0x2c
ub1 rowdata[19]                             @8164     0x01
ub1 rowdata[20]                             @8165     0x02
ub1 rowdata[21]                             @8166     0x02
ub1 rowdata[22]                             @8167     0xc1
ub1 rowdata[23]                             @8168     0x03
ub1 rowdata[24]                             @8169     0x07
ub1 rowdata[25]                             @8170     0x68
ub1 rowdata[26]                             @8171     0x75
ub1 rowdata[27]                             @8172     0x61
ub1 rowdata[28]                             @8173     0x74
ub1 rowdata[29]                             @8174     0x65
ub1 rowdata[30]                             @8175     0x6e
ub1 rowdata[31]                             @8176     0x67
ub1 rowdata[32]                             @8177     0x2c
ub1 rowdata[33]                             @8178     0x01
ub1 rowdata[34]                             @8179     0x02
ub1 rowdata[35]                             @8180     0x02
ub1 rowdata[36]                             @8181     0xc1
ub1 rowdata[37]                             @8182     0x02
ub1 rowdata[38]                             @8183     0x04
ub1 rowdata[39]                             @8184     0x63
ub1 rowdata[40]                             @8185     0x70
ub1 rowdata[41]                             @8186     0x69
ub1 rowdata[42]                             @8187     0x63


BBED> sum apply
Check value for File 0, Block 198:
current = 0x6245, required = 0x6245

BBED> verify
DBVERIFY - Verification starting
FILE = /test/orcl/orcl/users01.dbf
BLOCK = 198

Block Checking: DBA = 16777414, Block Type = KTB-managed data block
data header at 0x1104c7064
kdbchk: row locked by non-existent transaction
        table=0   slot=2
        lockid=2   ktbbhitc=2
Block 198 failed with check code 6101

DBVERIFY - Verification complete

Total Blocks Examined         : 1
Total Blocks Processed (Data) : 1
Total Blocks Failing   (Data) : 1
Total Blocks Processed (Index): 0
Total Blocks Failing   (Index): 0
Total Blocks Empty            : 0
Total Blocks Marked Corrupt   : 0
Total Blocks Influx           : 0


BBED> modify /x 2c00
 File: /test/orcl/orcl/users01.dbf (0)
 Block: 198              Offsets: 8145 to 8160           Dba:0x00000000
------------------------------------------------------------------------
 2c000202 c1040b79 616e7368 6f757065

 <32 bytes per line>

BBED> sum apply
Check value for File 0, Block 198:
current = 0x6045, required = 0x6045

BBED> verify
DBVERIFY - Verification starting
FILE = /test/orcl/orcl/users01.dbf
BLOCK = 198


DBVERIFY - Verification complete

Total Blocks Examined         : 1
Total Blocks Processed (Data) : 1
Total Blocks Failing   (Data) : 0
Total Blocks Processed (Index): 0
Total Blocks Failing   (Index): 0
Total Blocks Empty            : 0
Total Blocks Marked Corrupt   : 0
Total Blocks Influx           : 0

 

回到SQLPLUS中查看可以看到构造的记录已经查询到了。


SQL> select * from scott.t;

        ID NAME
---------- ------------------------------------------------------------
         1 cpic
         2 huateng
         3 yanshoupeng
