package middleware

import (
	"net/http"
	"strings"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"closeai-backend/models"
	"closeai-backend/utils"
)

func JWTAuth(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		tokenStr := c.GetHeader("Authorization")
		if tokenStr == "" || !strings.HasPrefix(tokenStr, "Bearer ") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "未登录"})
			return
		}
		tokenStr = strings.TrimPrefix(tokenStr, "Bearer ")
		claims, err := utils.ParseToken(tokenStr)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Token无效"})
			return
		}
		var user models.User
		db.First(&user, claims.UserID)
		if user.ID == 0 {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "用户不存在"})
			return
		}
		c.Set("user", user)
		c.Next()
	}
}
