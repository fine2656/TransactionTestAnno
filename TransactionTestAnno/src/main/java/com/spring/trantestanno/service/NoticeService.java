package com.spring.trantestanno.service;

import java.util.HashMap;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.spring.trantestanno.model.InterNoticeDAO;
import com.spring.trantestanno.model.NoticeVO;


//#15. Service 선언
// 서비스단에서 트랜잭션 처리를 해준다. 
// 서비스단의 패키지 이름은 포인트컷에 맞춰주어야 한다(servlet_context.xml)
@Service
public class NoticeService implements InterNoticeService {

	@Autowired //의존객체주입(DI : Dependency Injection) 
	private InterNoticeDAO dao;

	
	// 나의포인트 요청
	@Override
	public int getLoginUserPoint(String userid) {
		int point = dao.getLoginUserPoint(userid);
		return point;
	}
	
	
	// >>>>> 트랜잭션처리 안한 것 <<<<<< 
	@Override
	public int add_notransaction(NoticeVO ntvo) {
		int n = dao.insert_tx_notices(ntvo);
		int m = dao.update_tx_notices(ntvo.getWriterid());
		return (n+m);
	}
	
	// >>>>> 트랜잭션처리를 해야할 메소드에 @Transactional 어노테이션을 설정하면 된다. 
	//       rollbackFor={Throwable.class} 은 롤백을 해야할 범위를 말하는데 
	//       Throwable.class 은 error 및 exception 을 포함한 최상위 루트이다. 
	//       즉, 해당 메소드 실행시 발생하는 모든 error 및 exception 에 대해서 롤백을 하겠다는 말이다. 
	// 		{Throwable.class} 오류가 일어나는 최상위 루트
	@Override
	@Transactional(propagation=Propagation.REQUIRED, isolation=Isolation.READ_COMMITTED, rollbackFor={Throwable.class})  // n또는 m에서 오류가 발생 되어지면 rollback 한다
	public int add_transaction(NoticeVO ntvo) throws Throwable {
		int n = dao.insert_tx_notices(ntvo);
		int m = dao.update_tx_notices(ntvo.getWriterid());
		return (n+m);
	}

	@Override
	public List<HashMap<String, String>> list() {
		List<HashMap<String, String>> list = dao.list();
		return list;
	}


	@Override
	public HashMap<String, String> contentView(int seq) {
		HashMap<String, String> contentViewMap = dao.contentView(seq);
		return contentViewMap;
	}
	
}
