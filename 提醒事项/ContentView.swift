//
//  ContentView.swift
//  提醒事项
//
//  Created by 123 on 2021/5/22.
//

import SwiftUI

var formater  =  DateFormatter() //该open方法返回一个格式化时间初始化以及类型

func initUserData() -> [SingleToDo]{
    formater.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    var output : [SingleToDo] = []
    
    if let dataStored = UserDefaults.standard.object(forKey: "todoListdata") as?
    Data {
        let data  = try! decoder.decode([SingleToDo].self, from: dataStored) //.self表示类型，从dataStored解码为[SingleToDo]类型
        for item in data{
            if !item.deleted {
                output.append(SingleToDo(title: item.title, date: item.date, isChecked: item.isChecked, id: output.count,IsFavorite: item.IsFavorite)) //deleted默认是false
            }
        }
    }
    return output
}

//首页页面，这是由ContentView_Previews决定的
struct ContentView: View {
    
    //@的作用是动态加载监视，这里没有数据库，直接每次启动重新创建对象
//    @ObservedObject var userData : Todo = Todo(data: [SingleToDo(title: "写作业",date: Date()),
//                                                      SingleToDo(title: "复习",date: Date())])
    
    @ObservedObject var userData : Todo = Todo(data: initUserData()) //这里相当于new了一个Todo类
    
    //是否进入编辑子视图EditInPage.swift
    @State var showEditInpage = false
    
    //是否进入多选模式
    @State var EditingMode = false
    
    @State var selection : [Int] = [] //被选中的块
    
    @State var showLikesOnly : Bool = false
    
    //这是构造器
    var body: some View {
        ZStack{   //希望+按钮浮在待办事项上面，所以用ZStack，越往下面写的图标部件就越浮在上面
            
            NavigationView{    //NavigationView是一个大框
                //ScrollView是设置为可以滚动的，.vertial是指可以上下滚动
                ScrollView(.vertical, showsIndicators: true){
                    VStack{
                        ForEach(self.userData.todoList) {
                            item in
                            if !item.deleted {
                                if !self.showLikesOnly || item.IsFavorite { //如果处于showLikeOnly状态，那么只有isFavorite==TRUE才能显示；如果不处于showLikeOnly状态，则一律显示，不管isFavorite
                                    SingleCardView(index: item.id,
                                                   editingMode: self.$EditingMode,
                                                   selection : self.$selection)
                                        .environmentObject(self.userData)//不需要特意写构造器，这个是需要在子视图与父视图之间互通的、时刻在监视的变量。
                                        .padding(.horizontal) //横向上往左右两边留白
                                        .animation(.spring()) //进入与退出多选模式会滑动，过程动画
                                        .transition(.slide)  //删除添加会滑动
                                }
                                
                            }
                        }
                    }
                }
                .navigationBarTitle("提醒事项")
                // 添加多选按钮
                .navigationBarItems(trailing:
                                        HStack(spacing : 20){  //间隔20
                                            if self.EditingMode {
                                                deleteButton(selection: self.$selection).environmentObject(self.userData)
                                            }
                                            
                                            showLikesButton(showLikesOnly: self.$showLikesOnly)
                                            
                                            EditingButton(editingMode: self.$EditingMode,selection: self.$selection).imageScale(.large)
                                        }
                                        
                )
            }
            
            
            
            //➕图标
            HStack{
//                Spacer() //水平布局+spacer()，会到达很右边的位置
                VStack{
                    Spacer()
                    Button(action : {
                        self.showEditInpage = true
                    }){
                        Image(systemName: "plus.circle.fill") //注意图标名字写错是不报错的。
          //                .imageScale(.large) //这个还是不够大
                            .resizable()
                            .aspectRatio(contentMode: .fit) //自适应
                            .frame(width: 80)
                            .foregroundColor(.blue)
                            .padding() //不要太靠边，上下左右留一点白
                    }
                    .sheet(isPresented: self.$showEditInpage, content: {
                        EditInPage()
                            .environmentObject(self.userData)
                    })
                }
            }
        }
    }
}

//多选模式按钮
struct EditingButton : View {
    @Binding var editingMode : Bool
    @Binding var selection : [Int]
    
    var body: some View{
        Button(action:{
            self.editingMode.toggle()
            self.selection.removeAll()
        }){
//            Image(systemName: "gear")
            if editingMode {
                Text("取消")
            }
            else{
                Text("一键编辑")
            }
        }
    }
}

//加一个按钮，多选一键删除
struct deleteButton : View {
    @Binding var selection : [Int]
    @EnvironmentObject var userData : Todo
    
    
    var body: some View{
        Button(action: {
            for i in self.selection {
                self.userData.deleteTodo(id: i)
            }
        }){
//            Image(systemName: "trash")
//                .imageScale(.large)
            
            Text("一键删除")
        }
    }
}




struct showLikesButton : View{
    @Binding var showLikesOnly : Bool
    var body: some View{
        Button(action : {
            self.showLikesOnly.toggle()
        }){
//            Image(systemName: self.showLikesOnly ? "star.fill" : "star")
//                .imageScale(.large)
//                .foregroundColor(.yellow)
            
            if(self.showLikesOnly){
                Text("仅展示收藏")
            }
            else{
                Text("展示全部")
            }
        }
    }
}

//一个待办事项块
struct SingleCardView : View{
//    @State var isChecked : Bool = false //@State 会让程序移植盯着这个变量，一旦变更了值就会重新加载所有用到这个变量的代码，但是只适用于简单变量，且不跨越多个文件的情况。
//
    
    @EnvironmentObject var userData : Todo
    var index : Int
    
    @State var showEditPage = false
    
    @Binding var editingMode : Bool
    
    //多选模式下被选中的id列表
    @Binding var selection : [Int]
    
//    var title : String = ""
//    var date : Date = Date()
    
    //这是一个默认调用的构造器函数
    var body : some View{
        HStack {
            //长方形颜色
            Rectangle()
                .frame(width: 6)
                .foregroundColor(Color("Color" + String(self.index % 3)))
                
            
            
            
            
            //删除按钮
            if self.editingMode {
                Button(action:{
                    self.userData.deleteTodo(id: self.index)
                }){
                    Image(systemName: "trash")
                        .padding(.leading)
                }
            }
            
            
            
            
            
            //编辑事项按钮
            //按钮：点击事件-覆盖生效区域-传递数据
            Button(action: {
                if(!self.editingMode){
                    self.showEditPage = true //这里表示，点击那么show变量就会变成true，那么就跑到下面sheet那里查看ispresented是否为TRUE，为TRUE就执行content代码。
                }
            }){
                //下面是点击进入编辑区域，待办事项和空白处归为一组，因为都应该触发编辑模式
                Group{
                    //垂直布局的两行文字，.leading是靠左，alinment是对齐；spacing是是留白。
                    VStack(alignment: .leading, spacing: 6.0) {
                        Text(self.userData.todoList[index].title)
                            .foregroundColor(.black) //去除按钮导致的蓝色
                        Text(formater.string(from: self.userData.todoList[index].date) )
                            .foregroundColor(.black)
                    }
                    .padding(.leading) //留白作用，默认上下左右都留白
                    
                    //这是空格视图，作用是用空格填满所在位置的空间。这里写在VStack的右边，将导致VStack靠左。
                    Spacer()
                }
            }
            .sheet(isPresented: self.$showEditPage, content: { //跳转子视图用sheet，调用函数直接用action即可
                EditInPage(title:self.userData.todoList[index].title,
                           date: self.userData.todoList[index].date,
                           isFavorite: self.userData.todoList[index].IsFavorite,
                           id: self.index)   //setter不需要自己写，这里相当于new了
                    .environmentObject(self.userData) //变更会重新渲染
            })
            
            
            
            
            
            if self.userData.todoList[index].IsFavorite {
                Image(systemName :"star.fill")
                    .foregroundColor(.yellow)
                    
            }
            
            
            
            
            //✅按钮
            //注意这里如果写错图标的名字是不会报错的。也不会解析出任何东西，保持原状。
            if !self.editingMode {
                Image(systemName: self.userData.todoList[index].isChecked ? "checkmark.square.fill" : "square")
                    .imageScale(.large)
                    .padding(.trailing)  //只希望在尾部有留白
                    .onTapGesture {
    //                    self.userData.todoList[index].isChecked.toggle() //点击触发反转Bool
                        self.userData.check(id: self.index) //不但点击触发Bool反转，还会存一次数据
                    }
            }
            else{
                //多选模式
                Image(systemName: self.selection.firstIndex(where: {$0 == self.index}) == nil ?
                        "circle" : "checkmark.circle.fill")
                    .imageScale(.large)
                    .padding()
                    .onTapGesture {
                        if self.selection.firstIndex(where: {
                            $0 == self.index
                        })  == nil {
                            self.selection.append(self.index)
                        }
                        else{
                            self.selection.remove(at:
                                self.selection.firstIndex(where: {
                                    $0 == self.index
                                })!)
                        }
                    }
            }
            
        }.frame(height : 78) //这里是整个垂直布局的元素的高度设定
         .background(Color.white) //背景色，这里是白色是为了跟后面阴影做对比
         .cornerRadius(10)   //加圆角，注意这个不能和上面的顺序弄反，否则背景是长方形
         .shadow(radius: 10,x : 0,y : 10)  //注意要有背景色才能体现阴影，x是上面的阴影长度，y是下。
        
    }
    
}

//这个很重要，是实时预览的，里面那个函数是什么，实时预览就呈现其body的返回值
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        
    }
}

