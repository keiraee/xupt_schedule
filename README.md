# 西邮课表 · Android 客户端（Flutter / GetX）

从 `panel/` 的学校登录链路移植，**App 直连学校统一认证**，不需要 panel 后端。

## 能力

- 账号密码登录 `auth.xupt.edu.cn`（RSA 加密密码）
- 异常登录短信二次认证
- CAS / app-forward 进入 `gmis.xupt.edu.cn`
- 解析课表 HTML，周网格展示
- 学期切换、跳周、回到本周

## 运行

```powershell
cd xupt_schedule_app
flutter pub get
flutter run
```

真机 USB 调试即可。应用直接访问学校 HTTPS，无需本机服务。

## 结构

```text
lib/
  main.dart
  app/theme.dart
  core/                 # 日期与节次工具
  data/school/          # 直连学校：SSO + 解析
  modules/
    auth/               # 登录 + 二次验证
    schedule/           # 课表页
```

## 说明

- 密码只用于本次登录请求，不落盘
- Cookie 会话仅保存在本机 `shared_preferences`
- 学校若强制图形/滑块验证码，会提示先在浏览器完成一次登录
