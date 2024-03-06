# EIT(Electrical Impedance Tomography)기술을 이용한 심폐기능 영상화 
## 수치 시뮬레이션 기반 팬텀 실험에서 u-net을 활용한 deblurring.

### Introduction
EIT 영상 기술은 자가 호흡이 불가능한 환자의 병상 곁에서 비침습적으로 24시간 실시간 심폐기능을 모 니터링 할 수 있는 유일한 의료영상기술이다. 기존의 의료영상기술인 MRI와 CT는 측정을 위해 큰 기기 안에 환자가 들어가야 하기에 병상 곁 사용이 불가하며, MRI는 가격 부담, CT는 방사선 위험으로 인해 24시간 실 시간 모니터링이 불가하다. EIT는 인체에 무해한 크기의 주입 전류를 사용하고, 데이터 수집 속도가 심박수보 다 빠르며, 측정 기기가 작고 가볍기에 병상 곁에서 24시간 실시간 비침습적 심폐기능 모니터링이 가능하다.
숨을 들이쉴때, 폐의 용적이 증가하고 공기가 폐 안으로 유입된다. 이때, 공기는 전기가 통하지 않으므로 폐의 도전율은 감소한다. 즉, 인체 내부의 도전율 분포 변화로부터 폐의 크기 변화를 알 수 있다.

![D2A4BE35-5745-48DD-806C-A100D9DD0B1D](https://github.com/jmseo1216/EIT_Deblurring/assets/159675684/baa78a74-8460-4eb0-a15c-1c5e57579f8c)

### EIT 기술을 활용한 영상 복원 알고리즘
수치 시뮬레이션기반 팬텀 실험에서는 8개의 전극과 도메인(신체)안에 원형 모양(허파)을 추가하여 실험하였다. (COMSOL Multiphysics 에서 수행) <br>
인체(Ω)에 부착한 전극(Ɛ)를 사용하여 전류(I)를 주입하면, 전도도 분포 ($\gamma$)에 따라 왜곡된 전압 분포 (𝑢)가 형성된다.  
EIT는 생체 전기임피던스 데이터 $V \in R^m$ 로부터 인체 내 전기 전도도 분포 $\gamma \in R^n$ 를 영상화하므로, V에서 $\gamma$로 가는 함수 f를 찾는 문제로 볼 수 있다: $f(V) = \gamma$

#### Image Reconstruction 
심폐영상에서의 역문제(inverse problem)는 시간차(time-difference)데이터 V로 부터 시간차 영상 $\sigma$를 복원하는 것을 목표로 한다. <br>
Maxwell's Equations에 의해 다음과 같이 전류-전압 관계를 수식으로 나타낼 수 있다. <br>
$$\mathbb{S}\gamma = V$$ <br>
<p align="center">
  <img width="350" alt="sy=v" src="https://github.com/jmseo1216/EIT_Deblurring/assets/159675684/e42feab0-eb73-4857-90d9-52cb6226b8ae">
</p> <br>

- $\mathbb{S}$는 sensitivity matrix로 영상 도메인(Ω)과 전극위치, 전류 인가 패턴에 의존하며, row는 8개의 전극으로부터 전압데이터를 얻은 개수 40개 이고, col은 mesh size이다.<br>
- V는 time difference 데이터로 한 팬텀모형에 대해 8개의 전극으로부터 전압데이터를 얻은 개수 40개이다. <br>
- $\gamma$ 는 전도도 분포(영상에서 복원하고자 하는 픽셀값)이다. <br>

선형시스템 $\mathbb{S}\gamma = V$를 풀면 $\gamma$를 복원할 수 있지만 sensitivity matrix $\mathbb{S}$은 ill-conditioned 하기 때문에 정규화(regularization)과정이 필요하다. <br>
<p align="center">
  <img width="350" alt="sy=v" src="https://github.com/jmseo1216/EIT_Deblurring/assets/159675684/c37578f3-c104-42ab-bcf0-c1f750f33255">
</p> <br>

다음 사진은 위 식을 통해 얻은 하나의 원형 모앙의 팬텀실험 결과이다.<br>
<p align="center">
  <img width="250" alt="sy=v" src="https://github.com/jmseo1216/EIT_Deblurring/assets/159675684/71606ccc-85dc-46db-864e-5aebba2c3cc1">
</p> <br>

### Image reconstruction Algorithm using U-Net
위 식을 통해 얻은 $\gamma$는 정규화를 통해 선형시스템을 풀었지만 여전히 nonlinear inverse problem으로 인해 blur한 이미지를 얻는다.
이를 sharp한 이미지를 얻기위해 U-Net 모델을 이용하여 해결하고자 한다. <br>

![897F1CFC-1FF6-41C5-881D-85F9D3FB7700](https://github.com/jmseo1216/EIT_Deblurring/assets/159675684/4f365ea9-d896-436d-9097-9694d6cec85c)

- training set $\{\sigma_i, \sigma_i^exp\}_i$


