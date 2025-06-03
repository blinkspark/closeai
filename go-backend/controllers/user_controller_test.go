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
	"gorm.io/gorm"
)

var testDB *gorm.DB

func setupTestRouter() *httptest.Server {
	db, _ := config.InitDB()
	_ = models.MigrateUser(db) // 自动迁移表结构
	db.Exec("DELETE FROM users") // 清空用户表
	testDB = db
	r := routes.SetupRouter(db)
	return httptest.NewServer(r)
}

func TestRegisterAndLogin(t *testing.T) {
	ts := setupTestRouter()
	defer ts.Close()

	// 注册
	regBody := map[string]string{
		"username": "testuser",
		"email": "test@example.com",
		"password": "12345678",
	}
	regJSON, _ := json.Marshal(regBody)
	resp, err := http.Post(ts.URL+"/api/register", "application/json", bytes.NewBuffer(regJSON))
	if err != nil || resp.StatusCode != 200 {
		t.Fatalf("注册失败: %v, 状态码: %d", err, resp.StatusCode)
	}

	// 登录
	loginBody := map[string]string{
		"username": "testuser",
		"password": "12345678",
	}
	loginJSON, _ := json.Marshal(loginBody)
	resp, err = http.Post(ts.URL+"/api/login", "application/json", bytes.NewBuffer(loginJSON))
	if err != nil {
		t.Fatalf("登录请求失败: %v", err)
	}
	if resp.StatusCode != 200 {
		t.Fatalf("登录失败，状态码: %d", resp.StatusCode)
	}
	var loginResp map[string]string
	json.NewDecoder(resp.Body).Decode(&loginResp)
	token := loginResp["token"]
	if token == "" {
		t.Fatal("未返回token")
	}

	// 获取用户信息
	req, _ := http.NewRequest("GET", ts.URL+"/api/user", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err = http.DefaultClient.Do(req)
	if err != nil || resp.StatusCode != 200 {
		t.Fatalf("获取用户信息失败: %v, 状态码: %d", err, resp.StatusCode)
	}
}
