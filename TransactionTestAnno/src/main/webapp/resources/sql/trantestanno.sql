--- *** Spring의 트랜잭션 처리 *** ---
/* 

 ACID : 트랜잭션을 설명할 때 4가지 특징을 이용한다. 
 1) A 
   ㄱ. Atomicity ( 원자성 ) : 원자성은 트랜잭션 범위에 있는 모든 동작이
   모두 실행되거나 또는 모두 실행이 취소됨을 보장한다.
 2) C
   ㄱ. Consistency ( 일관성 ) : 트랜잭션이 종료되면, 시스템은 비즈니스에서
   기대하는 상태가 된다. 
   예) 서적 구매 트랜잭션이 성공적으로 실행되면 결제 내역, 구매 내역
   , 잔고 정보가 비즈니스에 맞게 저장되고 변경된다.

 3) I
   ㄱ. Isolation ( 고립성 ) : 트랜잭션은 다른 트랜잭션과 독립적으로 
   실행되어야 하며, 서로 다른 트랜잭션이 동일한 데이터에 동시에 접근
   할 경우 알맞게 동시 접근을 제어해야 한다. ( 격리레벨에 따라 동시 접근 제어 )  

 4) D
  ㄱ. Durability ( 지속성 ) : 트랜잭션이 완료되면, 그 결과는 지속적으로 
  유지되어야 한다. 


 === 트랜잭션 처리 상황 === 
 ㄱ. 계좌 이체 = 계좌출금 + 타 계좌입금
  *** ㄴ. 회원이 특정 게시판에 게시글을 추가하면 회원의 포인트가 올라가는 상황
 ㄷ. 원글에 댓글이 추가되면 댓글 테이블에 게시물 등록되고, 원글에는 댓글의 숫자가 업데이트되는 상황
 ㄹ. 문의 게시판에 글을 등록하면 데이터베이스에도 글이 등록되지만, 담당자에게도 메일이 발송되는 상황

*/
 

   create table tx_member
   (  id varchar2(50) 
    , pwd varchar2(50)
    , name varchar2(50)
    , point number(10) default 0
    , constraint PK_tx_member_id primary key(id)
    , constraint CK_tx_member_point check( point < 3 )
   );

   insert into tx_member(id, pwd, name) values('hongkd','1234','홍길동');
   insert into tx_member(id, pwd, name) values('eom','1234','엄정화');
   commit;
   

   create table tx_notices
   ( seq varchar2(10) 
   , writerid varchar2(50)
   , title varchar2(200) 
   , content varchar2(4000)
   , constraint PK_tx_notices_seq primary key(seq)
   , constraint FK_tx_notices_writerid foreign key(writerid) references tx_member(id)
   );
  alter table tx_notices modify(seq number);
  
   create sequence seq_tx_notices
   start with 1
   increment by 1
   nomaxvalue
   nominvalue
   nocycle
   nocache;
   
  
   
   
   insert into tx_notices(seq, writerid, title, content)
   values(seq_tx_notices.nextval, 'hongkd', '연습', '내용은연습입니다');
   
   update tx_member set point = point + 1
   where id = 'hongkd';
   /*
   오류 보고 -
   SQL 오류: ORA-02290: check constraint (MYORAUSER.CK_TX_MEMBER_POINT) violated
   */
   rollback;
   
   select * from tx_notices
   order by seq desc;
   
   select * from tx_member;
   
   select rno, seq, name, title, content
   from 
   (
     select row_number() over(order by seq) AS rno, seq, name, title, content
     from tx_notices N join tx_member M
     on N.writerid = M.id
   ) V    
   order by seq desc;
   
   delete from tx_notices;
   update tx_member set point = 0;
   commit;
   
   drop sequence seq_tx_notices;
   
   
   select previousSeq, previousTitle, seq, title, name, content, nextSeq, nextTitle
   from
   (
     select lead(N.seq, 1) over(order by N.seq desc) as previousSeq
          , lead(N.title, 1) over(order by N.seq desc) as previousTitle
          , N.seq 
          , N.title 
          , M.name
          , N.content
          , lag(N.seq, 1) over(order by N.seq desc) as nextSeq
          , lag(N.title, 1) over(order by N.seq desc) as nextTitle
     from tx_notices N join tx_member M 
     on N.writerid = M.id
   ) V
   where V.seq = 2;
   
   
   
   ----------------------------------------------------------------------------------------------
    
    select lag(to_number(seq)) over(order by to_number(seq) desc) AS 이전글번호
           ,lag(title) over(order by to_number(seq) desc) AS 이전글제목
           , to_number(seq) AS 현재글번호
           , title AS 현재글제목
           , lead(to_number(seq)) over(order by to_number(seq) desc) AS 다음글번호
           , lead(title) over(order by to_number(seq) desc) AS 다음글제목
    from tx_notices;
  
     
    select lag(현재글번호) over(order by V.현재글번호 desc) AS 이전글번호
    , lag(현재글제목) over(order by V.현재글번호 desc) AS 이전글제목 
    , 행번호,현재글제목,현재글번호
    , lead(현재글번호) over(order by V.현재글번호 desc) AS 다음글번호
    , lead(현재글제목) over(order by V.현재글번호 desc) AS 다음글제목
    from (   
            select row_number() over(order by to_number(seq) asc) AS 행번호
                   , to_number(seq) AS 현재글번호
                   , title AS 현재글제목
            from tx_notices
            order by to_number(seq) desc
    )V;
  
    -- 페이징 처리 --
            select  lag(to_number(seq)) over(order by to_number(seq) desc) AS 이전글번호
                    ,lag(title) over(order by to_number(seq) desc) AS 이전글제목
                   , row_number() over(order by to_number(seq) desc) AS 행번호
                   , to_number(seq) AS 현재글번호
                   ,M.name AS 작성자
                   , title AS 현재글제목
                   , content as 글내용
                   ,lead(to_number(seq)) over(order by to_number(seq) desc) AS 다음글번호
                   ,lead(title) over(order by to_number(seq) desc) AS 다음글제목
            from tx_notices N join tx_member M
            on N.writerid = M.id
            order by to_number(seq) desc;


---------->>
 select  lag(to_number(N.seq),2) over(order by to_number(N.seq) desc) AS previousSeq 
                    ,lag(N.title,2) over(order by to_number(N.seq) desc) AS previousTitle
                  -- , row_number() over(order by to_number(N.seq) desc) AS rno
                   , to_number(N.seq) AS seq
                   , M.name
                   , N.title
                   , N.content 
                   , lead(to_number(N.seq),2) over(order by to_number(N.seq) desc) AS nextSeq
                   , lead(N.title,2) over(order by to_number(N.seq) desc) AS nextTitle
            from tx_notices N join tx_member M
            on N.writerid = M.id
            order by to_number(seq) desc;
            --> 두칸씩 건너뛰기
            
            
            select previousSeq,previousTitle,seq,title,nextSeq,nextTitle,NAME,CONTENT
            from
             (
                 select  lag(to_number(N.seq)) over(order by to_number(N.seq) desc) AS previousSeq
                        ,lag(N.title) over(order by to_number(N.seq) desc) AS previousTitle
                       , to_number(N.seq) AS seq
                       , M.name
                       , N.title
                       , N.content 
                       , lead(to_number(N.seq)) over(order by to_number(N.seq) desc) AS nextSeq
                       , lead(N.title) over(order by to_number(N.seq) desc) AS nextTitle
                from tx_notices N join tx_member M
                on N.writerid = M.id
            )V
            where V.seq=4
            order by to_number(seq) desc;