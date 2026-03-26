export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type Database = {
  __InternalSupabase: {
    PostgrestVersion: "14.4";
  };
  public: {
    Tables: {
      categories: {
        Row: {
          created_at: string;
          id: number;
          is_active: boolean;
          name: string;
          parent_id: number | null;
        };
        Insert: {
          created_at?: string;
          id?: number;
          is_active?: boolean;
          name: string;
          parent_id?: number | null;
        };
        Update: {
          created_at?: string;
          id?: number;
          is_active?: boolean;
          name?: string;
          parent_id?: number | null;
        };
        Relationships: [
          {
            foreignKeyName: "categories_parent_id_fkey";
            columns: ["parent_id"];
            isOneToOne: false;
            referencedRelation: "categories";
            referencedColumns: ["id"];
          },
        ];
      };
      order_items: {
        Row: {
          created_at: string;
          id: number;
          order_id: number;
          price_at_purchase: number;
          product_id: number;
          quantity: number;
        };
        Insert: {
          created_at?: string;
          id?: number;
          order_id: number;
          price_at_purchase?: number;
          product_id: number;
          quantity?: number;
        };
        Update: {
          created_at?: string;
          id?: number;
          order_id?: number;
          price_at_purchase?: number;
          product_id?: number;
          quantity?: number;
        };
        Relationships: [
          {
            foreignKeyName: "order_items_order_id_fkey";
            columns: ["order_id"];
            isOneToOne: false;
            referencedRelation: "orders";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "order_items_product_id_fkey";
            columns: ["product_id"];
            isOneToOne: false;
            referencedRelation: "products";
            referencedColumns: ["id"];
          },
        ];
      };
      orders: {
        Row: {
          created_at: string;
          id: number;
          status: string;
          total_price: number;
          updated_at: string | null;
          user_id: string | null;
        };
        Insert: {
          created_at?: string;
          id?: number;
          status?: string;
          total_price?: number;
          updated_at?: string | null;
          user_id?: string | null;
        };
        Update: {
          created_at?: string;
          id?: number;
          status?: string;
          total_price?: number;
          updated_at?: string | null;
          user_id?: string | null;
        };
        Relationships: [];
      };
      payment_logs: {
        Row: {
          created_at: string;
          event_payload: Json | null;
          event_type: string;
          id: number;
          order_id: number;
          payment_id: number | null;
        };
        Insert: {
          created_at?: string;
          event_payload?: Json | null;
          event_type: string;
          id?: number;
          order_id: number;
          payment_id?: number | null;
        };
        Update: {
          created_at?: string;
          event_payload?: Json | null;
          event_type?: string;
          id?: number;
          order_id?: number;
          payment_id?: number | null;
        };
        Relationships: [
          {
            foreignKeyName: "payment_logs_order_id_fkey";
            columns: ["order_id"];
            isOneToOne: false;
            referencedRelation: "orders";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "payment_logs_payment_id_fkey";
            columns: ["payment_id"];
            isOneToOne: false;
            referencedRelation: "payments";
            referencedColumns: ["id"];
          },
        ];
      };
      payments: {
        Row: {
          amount: number;
          callback_payload: Json | null;
          checkout_request_id: string | null;
          created_at: string;
          customer_message: string | null;
          id: number;
          merchant_request_id: string | null;
          mpesa_receipt_number: string | null;
          order_id: number;
          phone_number: string | null;
          raw_request: Json | null;
          raw_response: Json | null;
          response_code: string | null;
          response_description: string | null;
          result_code: number | null;
          result_desc: string | null;
          status: string;
          transaction_date: string | null;
          updated_at: string;
          user_id: string;
        };
        Insert: {
          amount: number;
          callback_payload?: Json | null;
          checkout_request_id?: string | null;
          created_at?: string;
          customer_message?: string | null;
          id?: number;
          merchant_request_id?: string | null;
          mpesa_receipt_number?: string | null;
          order_id: number;
          phone_number?: string | null;
          raw_request?: Json | null;
          raw_response?: Json | null;
          response_code?: string | null;
          response_description?: string | null;
          result_code?: number | null;
          result_desc?: string | null;
          status?: string;
          transaction_date?: string | null;
          updated_at?: string;
          user_id: string;
        };
        Update: {
          amount?: number;
          callback_payload?: Json | null;
          checkout_request_id?: string | null;
          created_at?: string;
          customer_message?: string | null;
          id?: number;
          merchant_request_id?: string | null;
          mpesa_receipt_number?: string | null;
          order_id?: number;
          phone_number?: string | null;
          raw_request?: Json | null;
          raw_response?: Json | null;
          response_code?: string | null;
          response_description?: string | null;
          result_code?: number | null;
          result_desc?: string | null;
          status?: string;
          transaction_date?: string | null;
          updated_at?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "payments_order_id_fkey";
            columns: ["order_id"];
            isOneToOne: false;
            referencedRelation: "orders";
            referencedColumns: ["id"];
          },
        ];
      };
      product_images: {
        Row: {
          created_at: string;
          id: number;
          image_url: string;
          is_main: boolean;
          order: number;
          product_id: number;
        };
        Insert: {
          created_at?: string;
          id?: number;
          image_url: string;
          is_main?: boolean;
          order?: number;
          product_id: number;
        };
        Update: {
          created_at?: string;
          id?: number;
          image_url?: string;
          is_main?: boolean;
          order?: number;
          product_id?: number;
        };
        Relationships: [
          {
            foreignKeyName: "product_images_product_id_fkey";
            columns: ["product_id"];
            isOneToOne: false;
            referencedRelation: "products";
            referencedColumns: ["id"];
          },
        ];
      };
      products: {
        Row: {
          category_id: number | null;
          created_at: string;
          description: string | null;
          discount_percentage: number | null;
          id: number;
          is_active: boolean;
          price: number;
          stock_quantity: number;
          title: string;
          updated_at: string | null;
        };
        Insert: {
          category_id?: number | null;
          created_at?: string;
          description?: string | null;
          discount_percentage?: number | null;
          id?: number;
          is_active?: boolean;
          price?: number;
          stock_quantity?: number;
          title: string;
          updated_at?: string | null;
        };
        Update: {
          category_id?: number | null;
          created_at?: string;
          description?: string | null;
          discount_percentage?: number | null;
          id?: number;
          is_active?: boolean;
          price?: number;
          stock_quantity?: number;
          title?: string;
          updated_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "products_category_id_fkey";
            columns: ["category_id"];
            isOneToOne: false;
            referencedRelation: "categories";
            referencedColumns: ["id"];
          },
        ];
      };
      profiles: {
        Row: {
          address: string | null;
          created_at: string;
          email: string;
          id: string;
          name: string;
          phone: string | null;
          role: string;
          updated_at: string | null;
        };
        Insert: {
          address?: string | null;
          created_at?: string;
          email: string;
          id: string;
          name: string;
          phone?: string | null;
          role?: string;
          updated_at?: string | null;
        };
        Update: {
          address?: string | null;
          created_at?: string;
          email?: string;
          id?: string;
          name?: string;
          phone?: string | null;
          role?: string;
          updated_at?: string | null;
        };
        Relationships: [];
      };
      user_roles: {
        Row: {
          id: string;
          role: Database["public"]["Enums"]["app_role"];
          user_id: string;
        };
        Insert: {
          id?: string;
          role: Database["public"]["Enums"]["app_role"];
          user_id: string;
        };
        Update: {
          id?: string;
          role?: Database["public"]["Enums"]["app_role"];
          user_id?: string;
        };
        Relationships: [];
      };
      wishlist: {
        Row: {
          added_at: string;
          id: number;
          product_id: number;
          user_id: string;
        };
        Insert: {
          added_at?: string;
          id?: number;
          product_id: number;
          user_id: string;
        };
        Update: {
          added_at?: string;
          id?: number;
          product_id?: number;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "wishlist_product_id_fkey";
            columns: ["product_id"];
            isOneToOne: false;
            referencedRelation: "products";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "wishlist_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      is_admin: { Args: { _user_id: string }; Returns: boolean };
      reduce_stock: { Args: { product_id: number; qty: number }; Returns: undefined };
    };
    Enums: {
      app_role: "admin" | "customer";
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">;
type DefaultSchema = DatabaseWithoutInternals["public"];

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer RowType;
    }
    ? RowType
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer RowType;
      }
      ? RowType
      : never
    : never;

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer InsertType;
    }
    ? InsertType
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer InsertType;
      }
      ? InsertType
      : never
    : never;

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer UpdateType;
    }
    ? UpdateType
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer UpdateType;
      }
      ? UpdateType
      : never
    : never;

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never;

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never;

export const Constants = {
  public: {
    Enums: {
      app_role: ["admin", "customer"],
    },
  },
} as const;
