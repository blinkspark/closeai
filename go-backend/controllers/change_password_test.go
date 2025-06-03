package controllers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"closeai-backend/config"
	"closeai-backend/routes"
	"closeai-backend/models"
)

func TestChangePassword(t *testing.T) {
	db, _ := config.InitDB()
	_ = models.MigrateUser(db) // 自动迁移表结构
	db.Exec("DELETE FROM users")
	r := routes.SetupRouter(db)
	ts := httptest.NewServer(r)
	defer ts.Close()

	// 注册
	regBody := map[string]string{
		"username": "user2",
		"email": "user2@example.com",
		"password": "oldpass123",
	}
	regJSON, _ := json.Marshal(regBody)
	http.Post(ts.URL+"/api/register", "application/json", bytes.NewBuffer(regJSON))

	// 登录获取token
	loginBody := map[string]string{
		"username": "user2",
		"password": "oldpass123",
	}
	loginJSON, _ := json.Marshal(loginBody)
	resp, _ := http.Post(ts.URL+"/api/login", "application/json", bytes.NewBuffer(loginJSON))
	var loginResp map[string]string
	json.NewDecoder(resp.Body).Decode(&loginResp)
	token := loginResp["token"]

	// 修改密码
	changeBody := map[string]string{
		"old_password": "oldpass123",
		"new_password": "newpass456",
	}
	changeJSON, _ := json.Marshal(changeBody)
	req, _ := http.NewRequest("POST", ts.URL+"/api/change_password", bytes.NewBuffer(changeJSON))
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := http.DefaultClient.Do(req)
	if err != nil || resp.StatusCode != 200 {
		t.Fatalf("修改密码失败: %v, 状态码: %d", err, resp.StatusCode)
	}

	// 用新密码登录
	loginBody2 := map[string]string{
		"username": "user2",
		"password": "newpass456",
	}
	loginJSON2, _ := json.Marshal(loginBody2)
	resp, _ = http.Post(ts.URL+"/api/login", "application/json", bytes.NewBuffer(loginJSON2))
	if resp.StatusCode != 200 {
		t.Fatalf("新密码登录失败，状态码: %d", resp.StatusCode)
	}
}
