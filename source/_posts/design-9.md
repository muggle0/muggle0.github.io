---
title: 设计模式-组合模式（Composite）
date: 2020-02-02 17:34:18
tags: 设计模式
---

组合（Composite）模式的定义：有时又叫作部分-整体模式，它是一种将对象组合成树状的层次结构的模式，用来表示“部分-整体”的关系。组合模式使得客户端代码可以一致地处理单个对象和组合对象，无须关心自己处理的是单个对象，还是组合对象，这简化了客户端代码；

<!--more-->

# 模式结构

- 顶层抽象：树枝或者树叶的抽象接口
- 树枝：是组合中的叶节点对象，它没有子节点，用于实现抽象构件角色中 声明的公共接口。
- 树叶：是组合中的分支节点对象，它有子节点。它实现了抽象构件角色中声明的接口，它的主要作用是存储和管理子部件



# 源码导读

组合模式分为透明模式和安全模式；透明模式是在顶层抽象中声明了所有管理子对象的方法，树叶节点点和树枝节点对于客户端来说没有区别。安全模式是在顶层抽象中只声明叶子和树枝公有的抽象方法，而将对叶子和树枝的管理方法实现到对应的类中，因此客户端就需要区分该节点是树枝还是叶子从而调用对应的方法。

对组合模式来说，List Set等这些集合类属于不那么严格的组合模式。由于没有找到太好的源码，因此我在这里分别对透明模式和安全模式组合说明

透明模式：

```
public abstract class Component{
    private String name;
    public Component(string name)
    {
        this.name = name;
    }

    public abstract boolean Add(Component component);

    public abstract boolean Remove(Component component);

    public String getName(){
        return name;
    }
}

public class Branch extend Component{
    private List<Component> tree=new ArrayList<>();

    public Branch(String name){
        super(name);
    }

    public boolean add(Componet component){
        tree.add(component);
        return true;
    }

    public boolean Remove(Component component){
        tree.remove(component);
        return true;
    }
}

public class Leaf extend Component{

     public Leaf(String name){
        super(name);
    }

     public boolean add(Componet component){
        return false;
    }

    public boolean Remove(Component component){
        return false;
    }

}
```

安全模式：

```
public abstract class Component{
    private String name;
    public Component(string name)
    {
        this.name = name;
    }

    public String getName(){
        return name;
    }


}

public class Branch extend Component{
    private List<Component> tree=new ArrayList<>();

    public Branch(String name){
        super(name);
    }

    public boolean add(Componet component){
        tree.add(component);
        return true;
    }

    public boolean Remove(Component component){
        tree.remove(component);
        return true;
    }

    public List<Component> getTree(){
        return tree;
    }
}

public class Leaf extend Component{

     public Leaf(String name){
        super(name);
    }


}
```

组合模式适用的场景为需要表述一个系统（组件）的整体与部分的结构层次的场合；组合模式可对客户端隐藏组合对象和单个对象的不同，以便客户端可以使用用统一的接口使用组合结构中的所有对象，对于该类场合也适用于组合模式