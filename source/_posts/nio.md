---
title: nio学习笔记
date: 2019-04-26 11:49:48
tags: javase
---
作者：muggle

# nio介绍

传统的IO又称BIO，即阻塞式IO，NIO就是非阻塞IO了，而NIO在jdk1.7后又进行了升级成为nio.2也就是aio；
Java IO的各种流是阻塞的。这意味着，当一个线程调用`read() `或 `write()`时，该线程被阻塞，直到有一些数据被读取，或数据完全写入。该线程在此期间不能再干任何事情了。 Java NIO的非阻塞模式，使一个线程从某通道发送请求读取数据，但是它仅能得到目前可用的数据，如果目前没有数据可用时，就什么都不会获取。而不是保持线程阻塞，所以直至数据变的可以读取之前，该线程可以继续做其他的事情。 非阻塞写也是如此。一个线程请求写入一些数据到某通道，但不需要等待它完全写入，这个线程同时可以去做别的事情。 线程通常将非阻塞IO的空闲时间用于在其它通道上执行IO操作，所以一个单独的线程现在可以管理多个输入和输出通道（channel）。

<!--more-->

# nio相关的类

nio有四个很重要的类：`Selector`，`Channel`，`Buffer`，`Charset`
## Channel

 Channel通过节点流的getChannel()方法来获得，成员map()用来将其部分或全部数据映射为Buffer，成员read()、write()方法来读写数据，而且只能通过Buffer作为缓冲来读写Channel关联的数据。

Channel接口下有用于文件IO的`FileChannel`，用于UDP通信的`DatagramChannel`，用于TCP通信的`ocketChannel`、`ServerSocketChannel`，用于线程间通信的`Pipe.SinkChannel`、`Pipe.SourceChannel`等实现类。Channel也不是通过构造器来创建对象，而是通过节点流的getChannel()方法来获得，如通过`FileInputStream`、`FileOutputStream`、`andomAccessFile`的`getChannel()`获得对应的`FileChannel`。

  `Channel`中常用的方法有`map()`、`read()`、`write()`，`map()`用来将`Channel`对应的部分或全部数据映射成`MappedByteBuffer`（`ByteBuffer`的子类），`read()/write()`用于对Buffer读写数据。

## Buffer

Buffer是一个缓冲区，它是一个抽象类，常用的子类:`ByteBuffer`,`MappedByteBuffer`,`CharBuffer`,`DoubleBuffer`,`FloatBuffer`,`IntBuffer`,`LongBuffer`,`ShortBuffer`等，通过它可以用来装入数据和输出数据。Buffer没有构造器，使用类方法`allocate()`来创建对应的Buffer对象，当向Buffer写入数据后，在读取Buffer中数据之前应该调用flip()方法来设置Buffer中的数据位置信息，读取Buffer中数据之后应该调用`clear()`方法来清空原来的数据位置信息。`compact()`方法只会清除已经读过的数据。任何未读的数据都被移到缓冲区的起始处，新写入的数据将放到缓冲区未读数据的后面。

## charset

 Charset可以将Unicode字符串（CharBuffer）和字节序列（ByteBuffer）相互转化。

Java中默认使用Unicode字符集，可以通过Charset来处理字节序列和字符序列（字符串）之间的转换，其`availableCharsets()`静态方法可以获得当前JDK支持的所有字符集。调用Charset的静态方法`forName()`可以获得指定字符集对应的Charset对象，调用该对象的`newEncoder()`、`newDecoder()`可以获得对应的编码器、解码器，调用编码器的encode()可以将CharBuffer或String转换为ByteBuffer，调用解码器的`decode()`可以将ByteBuffer转换为CharBuffer。

 ## Selector

Selector允许单线程处理多个 Channel。如果你的应用打开了多个连接（通道），但每个连接的流量都很低，使用Selector就会很方便。Selector（选择器）是Java NIO中能够检测一到多个NIO通道，并能够知晓通道是否为诸如读写事件做好准备的组件。这样，一个单独的线程可以管理多个channel。通过调用`Selector.open()`方法创建一个Selector，将Channel注册到Selector上。通过`SelectableChannel.register()`方法来实现。与Selector一起使用时，Channel必须处于非阻塞模式下。这意味着不能将FileChannel与Selector一起使用，因为FileChannel不能切换到非阻塞模式。而套接字通道都可以。

# nio使用须知

缓冲区本质上是一块可以写入数据，然后可以从中读取数据的内存。这块内存被包装成NIO Buffer对象，并提供了一组方法，用来方便的访问该块内存。它的三个属性capacity,position和limit就是描述这块内存的了。capacity可以简单理解为这块内存的大小；写数据到Buffer中时，position表示当前的位置。初始的position值为0。当一个byte、long等数据写到Buffer后， position会向前移动到下一个可插入数据的Buffer单元。position最大可为capacity – 1.
当读取数据时，也是从某个特定位置读。当将Buffer从写模式切换到读模式，position会被重置为0. 当从Buffer的position处读取数据时，position向前移动到下一个可读的位置。limit表示你最多能读（写）多少数据。

buffer的方法：

- flip()：将Buffer从写模式切换到读模式。调用flip()方法会将position设回0，并将limit设置成之前position的值。
- get()：从Buffer中读取数据
- rewind()：将position设回0，所以你可以重读Buffer中的所有数据。limit保持不变，仍然表示能从Buffer中读取多少个元素（byte、char等）。
- clear()：position将被设回0，limit被设置成 capacity的值。换句话说，Buffer 被清空了。Buffer中的数据并未清除，只是这些标记告诉我们可以从哪里开始往Buffer里写数据。
- compact()：将所有未读的数据拷贝到Buffer起始处。然后将position设到最后一个未读元素正后面。limit属性依然像clear()方法一样，设置成capacity。
-  put()：向Buffer存入数据，带索引参数的版本不会移动位置position。
-  capacity()：获得Buffer的大小capacity。
-  hasRemaining()：判断当前位置position和界限limit之间是否还有元素可供处理。
-  remaining()：获得当前位置position和界限limit之间元素的个数。
-  limit()：获得或者设置Buffer的界限limit的位置。
-  position()：获得或者设置Buffer的位置position。
-  mark()：设置Buffer的mark位置。
-  reset()：将位置positon转到mark所在的位置。

# nio使用示例

NIO中，如果两个通道中有一个是FileChannel，那你可以直接将数据从一个channel传输到另外一个channel。

FileChannel的transferFrom()方法可以将数据从源通道传输到FileChannel中。

ransferTo()方法将数据从FileChannel传输到其他的channel中。

InputStream get出来的通道只能用于输入，outputStream同理

文件读操作

```java
File file = new File("test.txt");
FileInputStream fin = new FileInputStream(file);

FileChannel channel = fin.getChannel();
ByteBuffer buf = ByteBuffer.allocate(10);
int read = channel.read(buf);
while (read>0){
     buf.flip();
    byte[] array = new byte[10];
    int limit = buf.limit();
    if (limit>=10){
         buf.get(array);
    }else {
        array=new byte[limit];
        buf.get(array);
    }
    String s = new String(array);
    System.out.print(s);
    buf.clear();
     read = channel.read(buf);
    }
```

文件写操作

```java
RandomAccessFile rw = new RandomAccessFile("test.txt", "rw");
FileChannel channel = rw.getChannel();
ByteBuffer allocate = ByteBuffer.allocate(1000);
allocate.put("wwwww".getBytes());
allocate.flip();
channel.write(allocate);
channel.write(wrap);
//      wrap 不需要 flip()
ByteBuffer wrap = ByteBuffer.wrap("sssssssssssss".getBytes());
channel1.write(wrap);
rw.close()
```

通道间数据传输

```java
  RandomAccessFile rw = new RandomAccessFile("test.txt", "rw");
  RandomAccessFile rw2 = new RandomAccessFile("test2.txt", "rw");
  FileChannel channel = rw.getChannel();
  FileChannel channel2 = rw2.getChannel();
  channel2.transferFrom(channel,0,channel.size());
```

