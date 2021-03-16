import 'dart:convert';
import 'dart:math';

import 'package:Project1/TestVersion/PostPage.dart';
import 'package:Project1/TestVersion/SearchPage.dart';
import 'package:Project1/TestVersion/currentUserProfile/currentUserProfile.dart';
import 'package:Project1/TestVersion/commonElements.dart';
import 'package:Project1/TestVersion/notification.dart';
import 'package:Project1/TestVersion/showTrends.dart';
import 'package:Project1/TestVersion/trendsRec.dart';
import 'package:better_player/better_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'OtherUserProfile/OthersUserProfile.dart';
import 'ShowAllMessages.dart';
import 'addNewPost.dart';
import 'mainPage.dart';

class MealTimePage extends StatefulWidget {
  @override
  _MealTimePageState createState() => _MealTimePageState();
}

class _MealTimePageState extends State<MealTimePage> {
  String token = '';
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  var title;
var fetchBody;
String img;
/*Future<String>videoUrl(postId)async{
  var url = await FirebaseFirestore.instance.collection('Posts').doc(postId).get().then((value){
    print('trying to read video with link: ${value['Post Video']}');
    return value['Post Video'];
  });
  return url;
}*/

  @override
  void initState() {
    /*_controller = VideoPlayerController.network(img)//('https://firebasestorage.googleapis.com/v0/b/mealtime-36758.appspot.com/o/VID-20160222-WA0005.mp4?alt=media&token=dacee324-2cd5-48d1-abbb-d5797046ff51')//('http://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });*/
    getToken();

    firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(
        alert: true,
        badge: true,
        provisional: true,
        sound: true
      )
    );

    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        //_showItemDialog(message);
        final notification = message['notification'];
        setState(() {
          title = notification['title'];
          fetchBody= notification['body'];
          print('title=$title fetchBody=$fetchBody');
       //   messages.add(Message(
       //       title: notification['title'], body: notification['body']));
        });
      },
      //onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        //_navigateToItemDetail(message);
        final notification = message['data'];
        setState(() {
          title = notification['title'];
          fetchBody= notification['body'];
         /* messages.add(Message(
            title: '${notification['title']}',
            body: '${notification['body']}',
          ));*/
        });
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        //_navigateToItemDetail(message);
      },
    );
    super.initState();
  }

  void getToken() async {
    token = await firebaseMessaging.getToken();
  }
  //Menu Option
  static void _showDialog(context,userDocID,currentUserEmail,postDocumentID) {
    // flutter defined function
    Size size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
         content: Container(
           //alignment: Alignment.center,
           height:userDocID!=currentUserEmail?25:45.0,
           child: Column(
             children:[
               InkWell(onTap:(){
                 Navigator.pop(context);
                 userDocID==currentUserEmail
                 ?Navigator.push(context, MaterialPageRoute(builder: (_)=>UserProfile()))
                 :Navigator.push(context, MaterialPageRoute(builder: (_)=>OtherUserProfile(userDocID, currentUserEmail)));
               
               },
               child: Container(
                // width:180.0,
                 height:20.0,
                 child: Row(
                   children: [
                     Text('View profile'),
                   ],
                 ))),
                 SizedBox(height: 5.0,),

                userDocID!=currentUserEmail?Container():InkWell(onTap:(){
                 Navigator.pop(context);
                 confirmPostDelete(context, userDocID, currentUserEmail, postDocumentID);
                 /*userDocID==currentUserEmail
                 ?Navigator.push(context, MaterialPageRoute(builder: (_)=>UserProfile()))
                 :Navigator.push(context, MaterialPageRoute(builder: (_)=>OtherUserProfile(userDocID, currentUserEmail)));
               */
               },
               child: Container(
                // width:180.0,
                 height:20.0,
                 child: Row(
                   children: [
                     Text('Delete post'),
                   ],
                 ))),
             ]
           ),
         ),
        );
      },
    );
  }
  static void confirmPostDelete(context,userDocID,currentUserEmail,postDocumentID) {
    // flutter defined function
    Size size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
         content: Container(
           //alignment: Alignment.center,
           height:68.0,
           child: Column(
             children:[
               Text('Confirm delete'),
               Row(
                 children: [
                   Spacer(),
                   FlatButton(onPressed: (){Navigator.pop(context);}, child: Text('No')),
                   Spacer(),
                   FlatButton(onPressed: (){
                     FirebaseFirestore.instance.collection('Posts').doc(postDocumentID).delete();
                     Navigator.pop(context);
                   }, child: Text('Yes')),
                   Spacer(),
                 ],
               )
             ]
           ),
         ),
        );
      },
    );
  }
  String username;
  String userEmail;
  String userProfilePic;
  //VideoPlayerController _controller;
  String userDocumentID;
  bool isFollowed;
  var rng ;
  var rndItems;
  int likeCount;
  bool isLiked=false;
  bool likeRemoved=false;
  bool isRecommended=false;
  bool recommendationRemoved=false;
  bool removeSaving=false;
  bool isSaved=false;
  TextEditingController comment = TextEditingController();
  BetterPlayerController controller;
  String commentText;
  bool showLoading = false;
  String testLink;
  String currentUser;
  bool showRecipes=false;
  /* readUrl()async{
    var url = FirebaseFirestore.instance.collection('Posts').get().then((value){
      for(var links in value.docs){
        print('Rovpro ${links['tag']}');
        if(links['tag']=='video'){
          print("links['Post Video']= ${links['Post Video']}");
          return links['Post Video'];
        }
      }
    });
    print('url=== $url');
  }*/
  /* void tryReading(videoLink){
        testLink=videoLink;
       _controller = VideoPlayerController.network(videoLink)//('http://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });}*/
  /*Widget readVideo(videoLink){
     
   // String link;
    //link = videoLink;
    //print('video link: $videoLink');
   /* _controller = VideoPlayerController.network('http://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });*/
      //print('_controller.value.initialized: ${_controller.value.initialized}');
    return AspectRatio(
        aspectRatio: 16 / 20,
        child: BetterPlayer.network(
          videoLink,
          //"http://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4",
          betterPlayerConfiguration: BetterPlayerConfiguration(
            aspectRatio: 16 / 9,
          ),
        ),
      );
    /*_controller.value.initialized
              ? 
              AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: InkWell(
                    onTap: (){
                      setState(() {
                 _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
                   });
                    },
                      child: Stack(
                      children: [
                        VideoPlayer(_controller),
                       // ClosedCaption(text: _controller.value.caption.text),
                _ControlsOverlay(controller: _controller),
                    Container(alignment:Alignment.bottomCenter,child: VideoProgressIndicator(_controller, allowScrubbing: true)),
                      ],
                    ),
                  ),
                )
              : Container(child: Center(child:Text('Loading video...')),);*/
  }
 */ 
  likePost(postId,currentUserEmail,currentUserusername,postPublisherEmail,likeCount)async{
    setState(() {
      isLiked=true;
    });
    FirebaseFirestore.instance.collection('Posts').doc(postId).collection('likes').doc(currentUserEmail).set({
      'liker email':currentUserEmail,
      'published by': postPublisherEmail,
    })
      .then((value){
      FirebaseFirestore.instance.collection('users').doc(postPublisherEmail).collection('Notification').add({
      'other user email':currentUserEmail,
      'current user email':postPublisherEmail,
      'activity':'Like',
      'other user username':currentUserusername,
      'time':FieldValue.serverTimestamp(),
    });
    });
    if(likeCount==0){
       FirebaseFirestore.instance.collection('TrendsRecommendation').doc(postId).set({
        'postId':postId,
        'userEmail':postPublisherEmail,
        'time':FieldValue.serverTimestamp(),
      });
    }
  }
  removelikePost(postId,currentUserEmail,currentUserusername,postPublisherEmail,likeCount)async{
    FirebaseFirestore.instance.collection('Posts').doc(postId).collection('likes').doc(currentUserEmail).delete();
   if(likeCount==1){
       FirebaseFirestore.instance.collection('TrendsRecommendation').doc(postId).delete();
    }
   setState(() {
        print('likeRemoved= $likeRemoved');
        isLiked=false;
      });
  }
  recommendPost(postId,currentUserEmail,currentUserusername,postPublisherEmail)async{
    setState(() {
      isRecommended=true;
    });
    
   /* FirebaseFirestore.instance.collection('Posts').doc(postId).update({
      'numberOfRecommendation':FieldValue.increment(1),
    });*/
    FirebaseFirestore.instance.collection('Posts').doc(postId).collection('RecommendedBy').doc(currentUserEmail)
      //FirebaseFirestore.instance.collection('Posts').doc(postId).collection('Recommendation').doc(currentUserEmail)
      .set({
      'recommender email':currentUserEmail,
      'published by': postPublisherEmail,
      'postId':postId,
    });
    FirebaseFirestore.instance.collection('users').doc(currentUserEmail).collection('Recommended').doc(postId)
      //FirebaseFirestore.instance.collection('Posts').doc(postId).collection('Recommendation').doc(currentUserEmail)
      .set({
      'recommender email':currentUserEmail,
      'published by': postPublisherEmail,
      'postId':postId,
      'time':FieldValue.serverTimestamp(),
    })
      .then((value){
      FirebaseFirestore.instance.collection('users').doc(postPublisherEmail).collection('Notification').add({
      'other user email':currentUserEmail,
      'current user email':postPublisherEmail,
      'activity':'Recommend',
      'time':FieldValue.serverTimestamp(),
    });
    }).then((value){
      setState(() {
        isRecommended=false;
      });
    });
  }
  removeRecommendationPost(postId,currentUserEmail,postPublisherEmail)async{
    //FirebaseFirestore.instance.collection('Posts').doc(postId).collection('Recommendation').doc(currentUserEmail).delete()
   FirebaseFirestore.instance.collection('Posts').doc(postId).collection('RecommendedBy').doc(currentUserEmail).delete();
   FirebaseFirestore.instance.collection('users').doc(currentUserEmail).collection('Recommended').doc(postId).delete();          
  }
  savePost(postId,currentUserEmail,postPublisherEmail)async{
    await FirebaseFirestore.instance.collection('users').doc(currentUserEmail).collection('Save').doc(postId)
    .set({
      'postId':postId,
      'saver email':currentUserEmail,
      'postPublisherEmail':postPublisherEmail,
      'time':FieldValue.serverTimestamp(),
    });
  }
  removeSavePost(postId,currentUserEmail,postPublisherEmail)async{
    setState(() {
      removeSaving=true;
    });
    await FirebaseFirestore.instance.collection('users').doc(currentUserEmail).collection('Save').doc(postId).delete().then((value){
      setState((){
        removeSaving=false;
      });
    });
  }
  void commentBox(postId,commenterEmail){
    showModalBottomSheet(
    isScrollControlled:true,
    context: context,
        builder: (BuildContext context){
          return Container(
            height: MediaQuery.of(context).size.height-50,
            child:Scaffold(
              appBar: AppBar(
                title: Text('Comments',style: TextStyle(color:Colors.black),),
                centerTitle: true,
                elevation:0,
                leading: IconButton(icon:Icon(Icons.close,color: Colors.black,),onPressed: (){Navigator.pop(context);}),
                backgroundColor: Colors.white,
              ),
                body: ListView(
                  children: [
                    Container(
                       // alignment: Alignment.bottomCenter,
                        height: MediaQuery.of(context).size.height-200,
                        //color: Colors.blue,
                        child:StreamBuilder(
                          stream: FirebaseFirestore.instance.collection('Posts').doc(postId).collection('comments').orderBy('publicationTime', descending: false).snapshots(),
                          builder: (context, commentsSnapshot) {
                            if(commentsSnapshot.hasData){
                              return ListView.builder(
                              itemCount: commentsSnapshot.data.documents.length,
                              itemBuilder: (content,index){
                                DocumentSnapshot getCommentDetails = commentsSnapshot.data.documents[index];
                                return Container(
                                  padding:EdgeInsets.symmetric(horizontal:5.0),
                                  width:MediaQuery.of(context).size.width,
                                  child:Row(
                                    children:[
                                      StreamBuilder(
                                        stream: FirebaseFirestore.instance.collection('users').doc(getCommentDetails['email']).snapshots(),
                                        builder: (context, userSnapshot) {
                                          if(userSnapshot.hasData){
                                            DocumentSnapshot showCommenterDetails = userSnapshot.data;
                                            return Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                        width:40.0,
                                                        height:40.0,
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(30.0),
                                                          child: Image.network(
                                                            showCommenterDetails['Profile Picture'],
                                                            loadingBuilder:(buildContext,Widget child, ImageChunkEvent loadingProgress){
                                                      if(loadingProgress == null)return child;
                                                      return Center(
                                                        child: CircularProgressIndicator(
                                                          value: loadingProgress.expectedTotalBytes != null
                                                          ?loadingProgress.cumulativeBytesLoaded/loadingProgress.expectedTotalBytes
                                                          :null,
                                                        ),
                                                      );
                                                    }
                                                            ),
                                                        ),
                                                      ),
                                      Column(
                                        children: [
                                          Container(
                                                padding:EdgeInsets.symmetric(horizontal:5.0),
                                                width:MediaQuery.of(context).size.width-50,
                                                child:Text('${showCommenterDetails['username']}',maxLines: 1,style:TextStyle(fontWeight:FontWeight.bold))
                                          ),
                                          Container(
                                                padding:EdgeInsets.symmetric(horizontal:5.0),
                                                width:MediaQuery.of(context).size.width-50,
                                                child: Text('${getCommentDetails['comment']}')),
                                        ],
                                      ),
                                                  ],
                                                ),
                                                Divider(),
                                              ],
                                            );
                                          }else{return Center(child:Text('Loading...'));}
                                        }
                                      ),
                                    ]
                                  )
                                );
                              },
                            );}else{return Center(child:Text('Loading...'));}
                          }
                        ),
                      ),
                      Divider(),
                      Container(
                  width:MediaQuery.of(context).size.width,
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  //height: 50.0,
                  child: Row(
                    children: [
                      Container(
                        width:MediaQuery.of(context).size.width-60,
                        padding: EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          border:Border.all(),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: TextField(
                              controller: comment,
                              decoration: InputDecoration(
                                hintText: 'Enter your comment',
                              ),
                              maxLines: null,
                            ),
                      ),
                      Spacer(),
                     /* showLoading==true?Container(
                          alignment: Alignment.center,
                          width:40.0,
                          height:40.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.0),
                            color: Colors.green,
                          ),
                          child: Container(width:20.0,height:20.0,child: CircularProgressIndicator(backgroundColor: Colors.white,)),
                        ):*/Container(
                          alignment: Alignment.bottomCenter,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.0),
                            color: Colors.green,
                          ),
                          child:IconButton(
                            icon: Icon(Icons.send),
                            color:Colors.white,
                            onPressed: ()async{
                              //sendComment(postId,commenterEmail,comment.text);
                            setState((){
                              commentText = comment.text;
                              comment.clear();
                             // showLoading=true;
                              });
                              await FirebaseFirestore.instance.collection('Posts').doc(postId).collection('comments').add({
                              'email':commenterEmail,
                              'comment':commentText,
                              'publicationTime':FieldValue.serverTimestamp(),
                              });
                              await FirebaseFirestore.instance.collection('Posts').doc(postId).update({
                             'numberOfComments':FieldValue.increment(1),
                           });
                            },
                            )
                        )
                    ],
                  )
                ),
             
                  ],
                ),
            )
          );
        });
  }
  
        showPost(postId,currentUser){
      showModalBottomSheet(
        context: context,
        isScrollControlled:true,
         builder: (BuildContext context){
           Size size = MediaQuery.of(context).size;
           return Container(
             width:MediaQuery.of(context).size.width,
             height: MediaQuery.of(context).size.height-30,
             child: Scaffold(
               appBar: AppBar(
                 title:Text('Trends',style:TextStyle(color:Colors.black,fontWeight: FontWeight.bold)),
                 centerTitle: true,
                 elevation:0.0,
                 leading: IconButton(color:Colors.black,onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.close),),
                 backgroundColor: Colors.transparent,
               ),
               body: ShowTrends(postId, currentUser)
               ), );
         });
    }
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
         if(snapshot.hasData){ 
           return StreamBuilder(
            stream: FirebaseFirestore.instance.collection('users').doc(snapshot.data.email).snapshots(),
            builder: (context, streamSnapshot) {
             if(streamSnapshot.hasData){ 
               DocumentSnapshot getUserDetails = streamSnapshot.data;
              currentUser = snapshot.data.email;
              userProfilePic = getUserDetails['Profile Picture'];
              return StreamBuilder(
                stream: FirebaseFirestore.instance.collection('Posts').orderBy('publicationTime', descending: true).snapshots(),
                builder: (context, postsSnapshot) {
                 if(postsSnapshot.hasData){ return CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        brightness: Brightness.light,
                        backgroundColor: Colors.white,
                        pinned: true,
                        bottom: PreferredSize(
                            child: Column(), preferredSize: const Size.fromHeight(0.0)),
                        //messageIcon
                        leading: Container(
                          child: new IconButton(
                            icon: Icon(Icons.message),
                            iconSize: 25.0,
                            color: Colors.black,
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_)=>ShowAllMessages()));
                            },
                          ),
                        ),
                        title: Center(
                          child: Container(
                            child: Text(
                              'MealTime',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        centerTitle: false,
                        actions: [
                          //userProfile
                          InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_)=>UserProfile()));
                            },
                            child: Container(
                              height: 50.0,
                              child: Column(
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.all(8.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(30.0),
                                          child: CachedNetworkImage(
                                  width:40.0,
                                  height: 40.0,
                                  imageUrl: getUserDetails['Profile Picture'],
                                  progressIndicatorBuilder: (context, url, downloadProgress) => 
                                  Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                                  errorWidget: (context, url, error) => Icon(Icons.error),
                                            )
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SliverPadding(
                        padding: EdgeInsets.zero,
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              Container(
                                color: Colors.white,
                                //height: 150.0,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 10.0,
                                          ),
                                          Text("Recommandations",
                                              style: TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5.0,
                                    ),
                                    //Friends text
                                    Container(
                                        padding: const EdgeInsets.only(left: 10.0),
                                        width: MediaQuery.of(context).size.width,
                                        height: 120.0,
                                        child: StreamBuilder(
                                          stream: FirebaseFirestore.instance.collection('TrendsRecommendation').snapshots(),
                                          builder: (context,trendSnapshot){
                                            if(trendSnapshot.hasData){
                                              return ListView.builder(
                                                itemCount: trendSnapshot.data.documents.length,
                                                scrollDirection: Axis.horizontal,
                                                itemBuilder:(context,index){
                                                    DocumentSnapshot getTrendsInfo = trendSnapshot.data.documents[index];
                                                  return StreamBuilder(
                                                    stream: FirebaseFirestore.instance.collection('Posts').doc(getTrendsInfo['postId']).snapshots(),
                                                    builder: (context, postSnapshot) {
                                                      if(postSnapshot.hasData){
                                                        DocumentSnapshot postDetailsData = postSnapshot.data;
                                                        return StreamBuilder(
                                                          stream: FirebaseFirestore.instance.collection('users').doc(postDetailsData['userEmail']).snapshots(),
                                                          builder: (context, publisherSnapshot) {
                                                            if(publisherSnapshot.hasData){
                                                              DocumentSnapshot userSnapshot = publisherSnapshot.data;
                                                              return InkWell(
                                                                onTap: (){
                                                                  showPost(getTrendsInfo['postId'],snapshot.data.email);
                                                                },
                                                                child: Container(
                                                                  //width:100.0,
                                                                       // height: 100.0,
                                                                       //color: Colors.green,
                                                                        margin: EdgeInsets.all(8.0),
                                                                  child: Stack(
                                                                    children: [
                                                                      //post Picture
                                                                      Container(
                                                                        width:75.0,
                                                                        height: 75.0,
                                                                        decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              gradient: SweepGradient(
                                                                colors: [
                                                                  Colors.green[400],
                                                                  Colors.blue[400],
                                                                ],
                                                              )),
                                                               child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment.center,
                                                            children: [
                                                              Container(
                                                                width: 68.0,
                                                                height: 68.0,
                                                                decoration: BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                  color: Colors.grey,
                                                                ),
                                                                child: ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          90.0),
                                                                  child: CachedNetworkImage(
                                                         // width:40.0,
                                                         // height: 40.0,
                                                          imageUrl: postDetailsData['Post Picture'],
                                                          progressIndicatorBuilder: (context, url, downloadProgress) => 
                                                          Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                                                          errorWidget: (context, url, error) => Icon(Icons.error),
                                            )
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                                      ),
                                                                      Container(
                                                                        alignment: Alignment.bottomCenter,
                                                                        child: Column(
                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                          children:[
                                                                            SizedBox(height: 70.0,),
                                                                            Container(
                                                                              width: 80.0,
                                                                              alignment: Alignment.center,
                                                                              child: Text('${userSnapshot['username']}',
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              style: TextStyle(fontWeight: FontWeight.bold),),
                                                                            ),
                                                                          ]
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              );
                                                              }else{return Center(child:CircularProgressIndicator());}
                                                          }
                                                        );}else{ return Center(child:CircularProgressIndicator());}
                                                    }
                                                  );
                                                }
                                              );
                                            }else{
                                              return Center(child:CircularProgressIndicator());
                                            }
                                          },
                                        )),
                                        /*StreamBuilder(
                                          stream: FirebaseFirestore.instance.collection('users').where('email',isNotEqualTo:snapshot.data.email).snapshots(),
                                          builder: (context, usersSnapshot) {
                                            if(usersSnapshot.hasData){
                                              return ListView.builder(
                                              itemCount: usersSnapshot.data.documents.length,
                                              scrollDirection: Axis.horizontal,
                                              itemBuilder: (context, index) {
                                                DocumentSnapshot getUsersInfo = usersSnapshot.data.documents[index];
                                                var documentID = usersSnapshot.data.documents[index].documentID;
                                                return InkWell(
                                                  onTap:(){
                                                    Navigator.push(context, MaterialPageRoute(builder: (_)=>OtherUserProfile(documentID,snapshot.data.email)));
                                                  },
                                                    child: Container(
                                                    width: size.width*0.25,
                                                    height: size.height*0.05,
                                                    child: Column(
                                                      children: [
                                                        Container(
                                                          width: 50.0,
                                                          height: 50.0,
                                                          decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              gradient: SweepGradient(
                                                                colors: [
                                                                  Colors.green[400],
                                                                  Colors.blue[400],
                                                                ],
                                                              )),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment.center,
                                                            children: [
                                                              Container(
                                                                width: 45.0,
                                                                height: 45.0,
                                                                decoration: BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                  color: Colors.grey,
                                                                ),
                                                                child: ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          30.0),
                                                                  child: CachedNetworkImage(
                                                          width:40.0,
                                                          height: 40.0,
                                                          imageUrl: getUsersInfo['Profile Picture'],
                                                          progressIndicatorBuilder: (context, url, downloadProgress) => 
                                                          Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                                                          errorWidget: (context, url, error) => Icon(Icons.error),
                                            )
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: EdgeInsets.symmetric(horizontal:5.0),
                                                          //width: 100.0,
                                                          //height: 30.0,
                                                          child: Center(
                                                              child: Text('${getUsersInfo['username']}',
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 2,
                                                                  style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                  ))),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          }else{return Center(child:CircularProgressIndicator());}}
                                        )),
                                       */ Divider(),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      //Main Content
                        SliverPadding(
                        padding: EdgeInsets.zero,
                        sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((context, postIndex) {
                              DocumentSnapshot getAllPostsDetails = postsSnapshot.data.documents[postIndex];
                              var postDocumentID = postsSnapshot.data.documents[postIndex].documentID;
                          return Container(
                                      width:MediaQuery.of(context).size.width,
                                 // height: MediaQuery.of(context).size.height*0.71,
                               color:Colors.white,
                                      margin: EdgeInsets.only(top:0.0),
                                     // padding: EdgeInsets.only(bottom:100.0),
                                      //color: Colors.blue,
                                      child: Column(
                                        children:[
                                          //Picture Username City Time
                                          //SizedBox(height:10.0,),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal:5.0),
                                            width: size.width,
                                            child:StreamBuilder(
                                              stream: FirebaseFirestore.instance.collection('users').doc(getAllPostsDetails['userEmail']).snapshots(),
                                              builder: (context, publisherSnapshot) {
                                              DocumentSnapshot getPublisherDetails = publisherSnapshot.data;
                                                if(publisherSnapshot.hasData){
                                                  return Row(
                                                  children:[
                                                    Container(
                                                    width:50.0,
                                                    height:50.0,
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(30.0),
                                                      child:CachedNetworkImage(
                                                imageUrl: getPublisherDetails['Profile Picture'],
                                                progressIndicatorBuilder: (context, url, downloadProgress) => 
                                                        Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                                                errorWidget: (context, url, error) => Icon(Icons.error),
                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width:10.0),
                                                  Container(
                                                    alignment: Alignment.topLeft,
                                                    //width: size.width,
                                                   // color: Colors.blue,
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width:size.width*0.65,
                                                          child: Column(
                                                            children:[
                                                              SizedBox(height: 20.0,),
                                                              Row(
                                                              children: [
                                                                Expanded(child: Text('${getPublisherDetails['username']}',style:TextStyle(fontWeight: FontWeight.bold,fontSize:18.0))),
                                                              ],
                                                                ),
                                                              Row(
                                                                  children: [
                                                                    Expanded(child: Text('${getAllPostsDetails['location']}')),
                                                                   // Flexible(child: Text('${timeago.format(DateTime.tryParse(getAllPostsDetails['publicationTime'].toDate().toString()))}')),
                                                                  ],
                                                                ),
                                                                Container(
                                                                  alignment: Alignment.topRight,
                                                                  child: Text('${timeago.format(DateTime.tryParse(getAllPostsDetails['publicationTime'].toDate().toString()))}'),
                                                                ),
                                                            ]
                                                          ),
                                                        ),
                                                        IconButton(icon: Icon(Icons.more_vert), onPressed: (){_showDialog(context,getAllPostsDetails['userEmail'],snapshot.data.email,postDocumentID);}),
                                                      ],
                                                    ),
                                                  ),
                                                  //IconButton(icon: Icon(Icons.more_vert), onPressed: (){_showDialog(context,getAllPostsDetails['userEmail'],snapshot.data.email,postDocumentID);}),
                                                  ]
                                                );
                                             }else{return Center(child: CircularProgressIndicator());} }
                                            )
                                          ),
                                          
                                          SizedBox(height: 2.0,),
                                           getAllPostsDetails['title']==''&&getAllPostsDetails['ingredients']==''&&getAllPostsDetails['procedure']==''?Container():(showRecipes==true?InkWell(
                                             onTap: (){
                                               setState(() {
                                                 showRecipes=false;
                                               });
                                             },
                                              child: Container(
                                              padding: EdgeInsets.only(left:30.0,right:30.0),
                                              width:MediaQuery.of(context).size.width,
                                              height: 25.0,
                                              //color:Colors.blue,
                                              child: Text('Hide Recipe',
                                              style: TextStyle(
                                                fontSize:16.0,
                                                color:Colors.blue[900],
                                              ),
                                              ),
                                          ),
                                           ):InkWell(
                                             onTap: (){
                                               setState(() {
                                                 showRecipes=true;
                                               });
                                             },
                                              child: Container(
                                              padding: EdgeInsets.only(left:30.0,right:30.0),
                                              width:MediaQuery.of(context).size.width,
                                              height: 25.0,
                                              //color:Colors.blue,
                                              child: Text('View Recipe',
                                              style: TextStyle(
                                                fontSize:16.0,
                                                color:Colors.blue[900],
                                              ),
                                              ),
                                          ),
                                           )),
                                           showRecipes==true?Container(
                                             child:Column(
                                               children: [
                                                 getAllPostsDetails['title']==''?Container():Container(
                                                   alignment: Alignment.topLeft,
                                                   padding: EdgeInsets.symmetric(horizontal:20.0),
                                                   child: Text('Title:',style:TextStyle(fontWeight:FontWeight.bold))),
                                                   getAllPostsDetails['title']==''?Container():Container(
                                                   alignment: Alignment.topLeft,
                                                   padding: EdgeInsets.symmetric(horizontal:20.0),
                                                   child: Text('${getAllPostsDetails['title']}')),

                                                   getAllPostsDetails['ingredients']==''?Container():Container(
                                                   alignment: Alignment.topLeft,
                                                   padding: EdgeInsets.symmetric(horizontal:20.0),
                                                   child: Text('Ingredients:',style:TextStyle(fontWeight:FontWeight.bold))),
                                                   getAllPostsDetails['ingredients']==''?Container():Container(
                                                   alignment: Alignment.topLeft,
                                                   padding: EdgeInsets.symmetric(horizontal:20.0),
                                                   child: Text('${getAllPostsDetails['ingredients']}')),
                                                   SizedBox(height:size.height*0.01),
                                                   getAllPostsDetails['procedure']==''?Container():Container(
                                                   alignment: Alignment.topLeft,
                                                   padding: EdgeInsets.symmetric(horizontal:20.0),
                                                   child: Text('Procedure:',style:TextStyle(fontWeight:FontWeight.bold))),
                                                   getAllPostsDetails['procedure']==''?Container():Container(
                                                   alignment: Alignment.topLeft,
                                                   padding: EdgeInsets.symmetric(horizontal:20.0),
                                                   child: Text('${getAllPostsDetails['procedure']}')),
                                                   SizedBox(height:size.height*0.01),
                                               ],
                                             )
                                             ):Container(),
                                          Container(
                                            width:size.width,
                                            height:250.0,
                                          //  color:Colors.red[900],
                                           child:/* getAllPostsDetails['tag']=='video'?
                                           //Container()
                                           //readVideo()
                                           //readVideo(getAllPostsDetails['Post Video'])
                                           //Container()
                                           AspectRatio(
                                            aspectRatio: 16/20,
                                            child: BetterPlayer.network(
                                             getAllPostsDetails['Post Video'],
                                             // "http://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4",
                                              betterPlayerConfiguration: BetterPlayerConfiguration(
                                                aspectRatio: 16 / 9,
                                             ),
                                            ),
                                         )
                                           :*/CachedNetworkImage(
                                            imageUrl: getAllPostsDetails['Post Picture'],
                                            fit: BoxFit.cover,
                                            progressIndicatorBuilder: (context, url, downloadProgress) => 
                                                    Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                                            errorWidget: (context, url, error) => Icon(Icons.error),
                                      ),
                                          ),
                                          SizedBox(height: 3.0,),
                                          Container(
                                            width: MediaQuery.of(context).size.width,
                                            height: 20.0,
                                            //color:Colors.yellow,
                                            child: Row(
                                              children: [
                                                SizedBox(width:30.0),
                                                Icon(Icons.thumb_up,size:20.0,color: Colors.blue,),
                                                SizedBox(width:10.0),
                                                StreamBuilder(
                                                  stream: FirebaseFirestore.instance.collection('Posts').doc(postDocumentID).collection('likes').snapshots(),
                                                  builder: (context, likeSnapshot) {
                                                    //DocumentSnapshot getAllPostsDetails = postsSnapshot.data
                                                    if(likeSnapshot.hasData){
                                                      likeCount = likeSnapshot.data.documents.length;
                                                      return Text('${likeSnapshot.data.documents.length}',style:TextStyle(fontSize:16.0));}
                                                    else{return Text('Loading...');}
                                                  }
                                                ),
                                                //Text('${getAllPostsDetails['numberOfLikes']}',style:TextStyle(fontSize:16.0)),
                                                SizedBox(width:30.0),
                                                Icon(Icons.comment,size:20.0),
                                                SizedBox(width:10.0),
                                                StreamBuilder(
                                                  stream: FirebaseFirestore.instance.collection('Posts').doc(postDocumentID).collection('comments').snapshots(),
                                                  builder: (context, commentSnapshot) {
                                                    //DocumentSnapshot getAllPostsDetails = postsSnapshot.data
                                                    if(commentSnapshot.hasData){
                                                      return Text('${commentSnapshot.data.documents.length}',style:TextStyle(fontSize:16.0));}
                                                    else{return Text('Loading...');}
                                                  }
                                                )
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height:5.0,
                                          ),
                                          Divider(height: 3.0),
                                          SizedBox(
                                            height:5.0,
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal:30.0),
                                            width:MediaQuery.of(context).size.width,
                                            //height: 40.0,
                                            //color:Colors.blue,
                                            child: Text('${getAllPostsDetails['postText']}',
                                            /*overflow: TextOverflow.ellipsis,
                                            maxLines: 2,*/
                                            style: TextStyle(
                                              fontSize:16.0,
                                            ),
                                            ),
                                          ),
                                          Divider(height:3.0),
                                          Container(
                                            width: MediaQuery.of(context).size.width,
                                            height:40.0,
                                            child: Row(
                                             // scrollDirection: Axis.horizontal,
                                              children: [
                                                StreamBuilder(
                                                  stream: FirebaseFirestore.instance.collection('Posts').doc(postDocumentID).collection('likes').doc(snapshot.data.email).snapshots(),
                                                  // ignore: missing_return
                                                  builder: (context, likeSnapshot) {
                                                    if(likeSnapshot==null || likeSnapshot.hasData){
                                                      if(!likeSnapshot.data.exists){
                                                        return InkWell(
                                                      onTap:(){
                                                        setState(() {
                                                          //isLiked==false?isLiked=true:isLiked=false;
                                                          likePost(postDocumentID,snapshot.data.email,getUserDetails['username'],getAllPostsDetails['userEmail'],likeCount);
                                                        });
                                                      },
                                                      child: Container(
                                                        alignment: Alignment.center,
                                                        width:size.width*0.12,
                                                        height:30.0,
                                                        child:Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.thumb_up,size:20.0),
                                                           /* SizedBox(width:2.0),
                                                            Text('Like',style:TextStyle(fontSize:12.0)),*/
                                                          ],
                                                        ),
                                                        ),);
                                                
                                                      }else if(likeSnapshot!=null || likeSnapshot.data.exists){
                                                        print('Post liked');
                                                        return InkWell(
                                                          onTap:(){
                                                            removelikePost(postDocumentID,snapshot.data.email,getUserDetails['username'],getAllPostsDetails['userEmail'],likeCount);
                                                          },
                                                          child: Container(
                                                          alignment: Alignment.center,
                                                          width:size.width*0.12,
                                                          height:30.0,
                                                          color:Colors.blue,
                                                          child:Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Icon(Icons.thumb_up,color: Colors.white,size:20.0),
                                                             /* SizedBox(width:2.0),
                                                              Text('Liked',style:TextStyle(color:Colors.white,fontSize:12.0)),*/
                                                            ],
                                                          ),
                                                          ),
                                                        );
                                                      }
                                                       }else{return Center(child:Text('Loading...'));} }
                                                ),
                                               //VerticalDivider(thickness: 2.0,),
                                                InkWell(
                                                  onTap: (){
                                                    commentBox(postDocumentID,snapshot.data.email);
                                                    },
                                                  child: Container(
                                                    width: size.width*0.12,
                                                    height: 20.0,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children:[
                                                        Icon(Icons.comment,size:20.0),
                                                        /*SizedBox(width:2.0),
                                                        Text('Comment',style:TextStyle(fontSize:12.0)),*/
                                                      ]
                                                    ),
                                                  ),
                                                ),
                                                //VerticalDivider(thickness: 2.0,),
                                                //Recommendation
                                                StreamBuilder(
                                                  stream: FirebaseFirestore.instance.collection('users').doc(snapshot.data.email).collection('Recommended').doc(postDocumentID).snapshots(),
                                                  // ignore: missing_return
                                                  builder: (context, recommendationSnapshot) {
                                                    if(recommendationSnapshot==null || recommendationSnapshot.hasData){
                                                      if(!recommendationSnapshot.data.exists){
                                                        print('Post not recommended');
                                                        return InkWell(
                                                      onTap:(){
                                                        setState(() {
                                                          recommendPost(postDocumentID,snapshot.data.email,getUserDetails['username'],getAllPostsDetails['userEmail']);
                                                          //isLiked==false?isLiked=true:isLiked=false;
                                                          //likePost(postDocumentID,snapshot.data.email,getUserDetails['username'],getAllPostsDetails['userEmail']);
                                                        });
                                                      },
                                                      child: Container(
                                                        alignment: Alignment.center,
                                                        width:size.width*0.12,
                                                        height:30.0,
                                                        child:Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.recommend,size:20.0),
                                                            /*SizedBox(width:2.0),
                                                            Text('Recommend',style: TextStyle(fontSize:12.0)),*/
                                                          ],
                                                        ),
                                                        ),);
                                                
                                                      }else if(recommendationSnapshot!=null || recommendationSnapshot.data.exists){
                                                        print('Post recommended');
                                                        return InkWell(
                                                          onTap:(){
                                                            removeRecommendationPost(postDocumentID,snapshot.data.email,getAllPostsDetails['userEmail']);
                                                            //removelikePost(postDocumentID,snapshot.data.email,getUserDetails['username'],getAllPostsDetails['userEmail']);
                                                          },
                                                          child: Container(
                                                            //padding: EdgeInsets.symmetric(horizontal:20.0),
                                                          alignment: Alignment.center,
                                                          width:size.width*0.12,
                                                          height:30.0,
                                                          color:Colors.blue,
                                                          child:Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Icon(Icons.recommend,color: Colors.white,size:20.0),
                                                              /*SizedBox(width:2.0),
                                                              Text('Recommended',style:TextStyle(color:Colors.white,fontSize:12.0)),*/
                                                            ],
                                                          ),
                                                          ),
                                                        );
                                                      }
                                                       }else{return Center(child:Text('Loading...'));} }
                                                ),
                                               //VerticalDivider(thickness: 2.0,),
                                                //Save Posts
                                                StreamBuilder(
                                                  stream: FirebaseFirestore.instance.collection('users').doc(snapshot.data.email).collection('Save').doc(postDocumentID).snapshots(),
                                                  // ignore: missing_return
                                                  builder: (context, saveSnapshot) {
                                                    if(saveSnapshot==null || saveSnapshot.hasData){
                                                      if(!saveSnapshot.data.exists){
                                                        return InkWell(
                                                      onTap:(){
                                                        setState(() {
                                                          savePost(postDocumentID,snapshot.data.email,getAllPostsDetails['userEmail']);
                                                          });
                                                      },
                                                      child: Container(
                                                        alignment: Alignment.center,
                                                        width:size.width*0.12,
                                                        height:30.0,
                                                        child:Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.download_rounded,size:20.0),
                                                            /*SizedBox(width:2.0),
                                                            Text('Save',style: TextStyle(fontSize:12.0)),*/
                                                          ],
                                                        ),
                                                        ),);
                                                
                                                      }else if(saveSnapshot!=null || saveSnapshot.data.exists){
                                                        return InkWell(
                                                          onTap:(){
                                                            removeSavePost(postDocumentID,snapshot.data.email,getAllPostsDetails['userEmail']);
                                                            },
                                                          child: Container(
                                                          alignment: Alignment.center,
                                                          width:size.width*0.12,
                                                          height:30.0,
                                                          color:Colors.blue,
                                                          child:Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Icon(Icons.download_done_rounded,color: Colors.white,size:20.0),
                                                             /* SizedBox(width:2.0),
                                                              Text('Saved',style:TextStyle(color:Colors.white,fontSize:12.0)),*/
                                                            ],
                                                          ),
                                                          ),
                                                        );
                                                      }
                                                       }else{return Center(child:Text('Loading...'));} }
                                                ),
                                               
                                              ],
                                            ),
                                          ),
                                         /* SizedBox(
                                            height:5.0,
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal:30.0),
                                            width:MediaQuery.of(context).size.width,
                                            //height: 40.0,
                                            //color:Colors.blue,
                                            child: Text('${getAllPostsDetails['postText']}',
                                            /*overflow: TextOverflow.ellipsis,
                                            maxLines: 2,*/
                                            style: TextStyle(
                                              fontSize:16.0,
                                            ),
                                            ),
                                          ),*/
                                          Divider(thickness: 5.0,),
                                        ],
                                      ),
                                    );
                               
                          /*Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            width: size.width,
                            height: 505.0,
                            color: Colors.white,
                            child: Column(
                              children: [
                                //Picture Username City Time
                                SizedBox(
                                  height: 10.0,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    //Profile picture
                                    SizedBox(
                                      width: 5.0,
                                    ),
                                    Container(
                                      width: 40.0,
                                      height: 40.0,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(30.0),
                                        child: Image.asset('image/corvet.jpg'),
                                      ),
                                    ),
                                    //Username
                                    Container(
                                        width: 280.0,
                                        height: 40.0,
                                        //color:Colors.red[900],
                                        child: Column(
                                          children: [
                                            Container(
                                                height: 20,
                                                //color:Colors.red,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    SizedBox(width: 20.0),
                                                    Text('Username',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 20.0)),
                                                  ],
                                                )),
                                            Container(
                                              height: 20,
                                              //color:Colors.red,
                                              child: Row(
                                                children: [
                                                  SizedBox(width: 20.0),
                                                  Row(children: [
                                                    //City
                                                    Container(
                                                        height: 20.0,
                                                        width: 100.0,
                                                        // color:Colors.red,
                                                        child: Text('Accra Ghana',
                                                            style:
                                                                TextStyle(fontSize: 16.0))),
                                                    //Time
                                                    Container(
                                                        height: 25.0,
                                                        width: 90.0,
                                                        // color:Colors.red,
                                                        child: Text('2m ago',
                                                            style:
                                                                TextStyle(fontSize: 16.0))),
                                                  ])
                                                ],
                                              ),
                                              /*Text('Accra-Ghana',style:TextStyle(fontWeight: FontWeight.bold,fontSize:17.0)),
                                                        ],
                                                      )*/
                                            ),
                                          ],
                                        )),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                            icon: Icon(Icons.more_vert), onPressed: () {}),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10.0,
                                ),
                                Container(
                                  padding: EdgeInsets.only(left: 30.0, right: 30.0),
                                  width: MediaQuery.of(context).size.width,
                                  height: 40.0,
                                  //color:Colors.blue,
                                  child: Text(
                                    'Today I personally made this ice cream from some rare recipes I want to share with you all Today I personally made this ice cream from some rare recipes ',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {},
                                  child: Container(
                                    padding: EdgeInsets.only(left: 30.0, right: 30.0),
                                    width: MediaQuery.of(context).size.width,
                                    height: 25.0,
                                    //color:Colors.blue,
                                    child: Text(
                                      'View Recipe',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 360,
                                  height: 300.0,
                                  color: Colors.grey[500],
                                  child: Image.asset(
                                    'image/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(
                                  height: 6.0,
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: 20.0,
                                  //color:Colors.yellow,
                                  child: Row(
                                    children: [
                                      SizedBox(width: 30.0),
                                      Icon(Icons.thumb_up, size: 20.0),
                                      SizedBox(width: 10.0),
                                      Text('124', style: TextStyle(fontSize: 16.0)),
                                      SizedBox(width: 30.0),
                                      Text('12 Comments', style: TextStyle(fontSize: 16.0))
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 5.0,
                                ),

                                Container(
                                  margin: const EdgeInsets.only(left: 8.0),
                                  width: MediaQuery.of(context).size.width,
                                  height: 30.0,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(width: 0.0),
                                          IconButton(
                                              icon: Icon(Icons.thumb_up, size: 20.0),
                                              onPressed: () {}),
                                          Container(
                                              padding:
                                                  EdgeInsets.only(top: 4.0, right: 1.0),
                                              child: Text('Like',
                                                  style: TextStyle(fontSize: 14.0))),
                                          SizedBox(
                                            width: 0.0,
                                          ),
                                          IconButton(
                                              icon: Icon(Icons.comment, size: 20.0),
                                              onPressed: () {}),
                                          Container(
                                              padding:
                                                  EdgeInsets.only(top: 4.0, right: 1.0),
                                              child: Text('Comment',
                                                  style: TextStyle(fontSize: 14.0))),
                                          SizedBox(
                                            width: 0.0,
                                          ),
                                          IconButton(
                                              icon: Icon(Icons.recommend, size: 20.0),
                                              onPressed: () {}),
                                          Container(
                                              padding:
                                                  EdgeInsets.only(top: 4.0, right: 1.0),
                                              child: Text('Recommend',
                                                  style: TextStyle(fontSize: 14.0))),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );0
                   */     }, childCount: postsSnapshot.data.documents.length-1)),
                      ),
                    ],
                  );
               }else{return Center(child: CircularProgressIndicator());} }
              );
          }else{return Center(child:CircularProgressIndicator());}  }
          );
      }else{return Center(child:CircularProgressIndicator());}  }
      ),
      //BottomAppBar
      bottomNavigationBar: BottomAppBar(
      child: Builder(builder: (context)=>Container(
     // padding: EdgeInsets.only( bottom: MediaQuery.of(context).viewInsets.bottom),
      width: MediaQuery.of(context).size.width,
      child:Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Container(width:(MediaQuery.of(context).size.width)/5,child: MaterialButton(height:47.0,color:Colors.blue,child:Icon(Icons.home,color:Colors.white), onPressed: ()=>null)),
                Container(width:(MediaQuery.of(context).size.width)/5,child: MaterialButton(height:47.0,child:Image.asset('image/recomend.png',height: 30.0,)/*Icon(Icons.people,color:Colors.black)*/, onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (_)=>TrendsRecommendation(currentUser,userProfilePic)));})),
                Container(width:(MediaQuery.of(context).size.width)/5,child: MaterialButton(height:47.0,child:Icon(Icons.camera_enhance,color:Colors.black), onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (_)=>AddNewPost(currentUser,userProfilePic)/*PostPage(currentUser)*/));})),
                Container(width:(MediaQuery.of(context).size.width)/5,child: MaterialButton(height:47.0,child:Icon(Icons.notifications,color:Colors.black), onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (_)=>Notifications()) );},)),
                Container(width:(MediaQuery.of(context).size.width)/5,child: MaterialButton(height:47.0,child:Icon(Icons.search,color:Colors.black), onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (_)=>SearchPage()));},))
              ],
            ),
),),
    ),
      //CommonElements.customBottomAppBar(),
      /*BottomAppBar(
      //  shape: CircularNotchedRectangle(),
        color:Colors.white,
        child: Container(
     // padding: EdgeInsets.only( bottom: MediaQuery.of(context).viewInsets.bottom),
      width: MediaQuery.of(context).size.width,
      child:Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Container(width:(MediaQuery.of(context).size.width)/5,child: MaterialButton(height:47.0,child:Icon(Icons.home,color:Colors.black), onPressed: (){})),
                Container(width:(MediaQuery.of(context).size.width)/5,child: MaterialButton(height:47.0,child:Image.asset('image/recomend.png',height: 30.0,)/*Icon(Icons.people,color:Colors.black)*/, onPressed: (){})),
                Container(width:(MediaQuery.of(context).size.width)/5,child: MaterialButton(height:47.0,child:Icon(Icons.camera_enhance,color:Colors.black), onPressed: (){})),
                Container(width:(MediaQuery.of(context).size.width)/5,child: MaterialButton(height:47.0,child:Icon(Icons.notifications,color:Colors.black), onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (_)=>Notifications()) );},)),
                Container(width:(MediaQuery.of(context).size.width)/5,child: MaterialButton(height:47.0,child:Icon(Icons.search,color:Colors.black), onPressed: (){},))
              ],
            ),
),
      ),*/
    );
  }
}
class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({this.controller});


  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: Duration(milliseconds: 50),
          reverseDuration: Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
@immutable
class Message {
  final String keyWord;

  const Message({
    @required this.keyWord,
  });
}
